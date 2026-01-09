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
}

resource "aws_security_group" "this" {
  name        = "${local.name}-sg-rds"
  description = "RDS Postgres SG"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Postgres from allowed SGs"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.allowed_sg_ids
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name}-sg-rds" })
}

resource "aws_db_subnet_group" "this" {
  name       = "${local.name}-db-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = merge(local.common_tags, { Name = "${local.name}-db-subnet-group" })
}

resource "aws_db_instance" "this" {
  identifier = "${local.name}-postgres"

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]

  publicly_accessible = false
  multi_az            = false

  backup_retention_period = 1
  deletion_protection     = false
  skip_final_snapshot     = true
  apply_immediately       = true

  tags = merge(local.common_tags, { Name = "${local.name}-postgres" })
}
