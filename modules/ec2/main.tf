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

# Terraform generates a new SSH keypair
resource "tls_private_key" "ec2" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Upload public key to AWS
resource "aws_key_pair" "this" {
  key_name   = var.key_name
  public_key = tls_private_key.ec2.public_key_openssh

  tags = merge(local.common_tags, {
    Name = "${local.name}-keypair"
  })
}

# Save private key to local disk (in the ROOT stack folder)
resource "local_file" "private_key" {
  filename        = "${path.root}/${var.private_key_filename}"
  content         = tls_private_key.ec2.private_key_pem
  file_permission = "0400"
}

resource "aws_security_group" "this" {
  name        = "${local.name}-sg-ec2"
  description = "EC2 jump host SG"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from admin IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ssh_cidr]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name}-sg-ec2" })
}

resource "aws_instance" "this" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.this.key_name
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.this.id]

  associate_public_ip_address = true

  tags = merge(local.common_tags, {
    Name = "${local.name}-ec2-jump"
    Role = "jump"
  })

  depends_on = [local_file.private_key]
}
