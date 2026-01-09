locals {
  name = "${var.project_name}-${var.environment}"

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )

  # NAT count: per AZ unless single_nat_gateway=true
  nat_count = var.single_nat_gateway ? 1 : length(var.public_subnet_cidrs)

  # NAT gateway mapping per AZ index
  nat_gateway_id_by_az = [
    for i in range(length(var.public_subnet_cidrs)) :
    (var.single_nat_gateway ? aws_nat_gateway.main[0].id : aws_nat_gateway.main[i].id)
  ]
}

# ---------------------
# VPC
# ---------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${local.name}-vpc"
  })
}

# ---------------------
# Subnets
# ---------------------

# Public (Web)
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${local.name}-subnet-public-${count.index + 1}"
    Tier = "public"
    Role = "web"
  })
}

# Private (App)
resource "aws_subnet" "app" {
  count             = length(var.app_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.app_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(local.common_tags, {
    Name = "${local.name}-subnet-app-${count.index + 1}"
    Tier = "private"
    Role = "app"
  })
}

# Private (DB) - NOT public
resource "aws_subnet" "db" {
  count             = length(var.db_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(local.common_tags, {
    Name = "${local.name}-subnet-db-${count.index + 1}"
    Tier = "private"
    Role = "database"
  })
}

# ---------------------
# Internet Gateway (IGW)
# ---------------------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name}-igw"
  })
}

# ---------------------
# NAT Gateway(s) (NGW)
# ---------------------
resource "aws_eip" "nat" {
  count  = local.nat_count
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${local.name}-eip-nat-${count.index + 1}"
  })
}

resource "aws_nat_gateway" "main" {
  count         = local.nat_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = var.single_nat_gateway ? aws_subnet.public[0].id : aws_subnet.public[count.index].id

  tags = merge(local.common_tags, {
    Name = "${local.name}-ngw-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.main]
}

# ---------------------
# Route Tables
# ---------------------

# Public route table -> IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.name}-rt-public"
  })
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# App route tables (per AZ) -> NAT
resource "aws_route_table" "app" {
  count  = length(var.app_subnet_cidrs)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = local.nat_gateway_id_by_az[count.index]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name}-rt-app-${count.index + 1}"
  })
}

resource "aws_route_table_association" "app" {
  count          = length(var.app_subnet_cidrs)
  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.app[count.index].id
}

# DB route tables (per AZ) -> NAT (NO IGW route)
resource "aws_route_table" "db" {
  count  = length(var.db_subnet_cidrs)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = local.nat_gateway_id_by_az[count.index]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name}-rt-db-${count.index + 1}"
  })
}

resource "aws_route_table_association" "db" {
  count          = length(var.db_subnet_cidrs)
  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.db[count.index].id
}

# ---------------------
# Network ACLs (NACL)
# ---------------------
resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.public[*].id

  tags = merge(local.common_tags, {
    Name = "${local.name}-nacl-public"
  })
}

resource "aws_network_acl" "app" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.app[*].id

  tags = merge(local.common_tags, {
    Name = "${local.name}-nacl-app"
  })
}

resource "aws_network_acl" "db" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.db[*].id

  tags = merge(local.common_tags, {
    Name = "${local.name}-nacl-db"
  })
}

# allow all in/out (Security Groups should enforce actual restrictions)
resource "aws_network_acl_rule" "allow_all" {
  for_each = {
    public_in  = { acl = aws_network_acl.public.id, egress = false }
    public_out = { acl = aws_network_acl.public.id, egress = true  }
    app_in     = { acl = aws_network_acl.app.id,    egress = false }
    app_out    = { acl = aws_network_acl.app.id,    egress = true  }
    db_in      = { acl = aws_network_acl.db.id,     egress = false }
    db_out     = { acl = aws_network_acl.db.id,     egress = true  }
  }

  network_acl_id = each.value.acl
  rule_number    = 100
  egress         = each.value.egress
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}
