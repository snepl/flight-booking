locals {
  name = "${var.project_name}-${var.environment}"
  common_tags = merge({
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }, var.tags)
}

resource "aws_security_group" "alb" {
  name        = "${local.name}-sg-alb"
  description = "ALB SG"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = var.listener_port
    to_port     = var.listener_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name}-sg-alb" })
}

resource "aws_lb" "this" {
  name               = "${local.name}-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  tags = merge(local.common_tags, { Name = "${local.name}-alb" })
}
