locals {
  name = "${var.project_name}-${var.environment}"
  common_tags = merge({
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }, var.tags)

  log_group_name = "/ecs/${local.name}/${var.container_name}"
}

resource "aws_ecs_cluster" "this" {
  name = "${local.name}-ecs"
  tags = merge(local.common_tags, { Name = "${local.name}-ecs" })
}

resource "aws_cloudwatch_log_group" "this" {
  name              = local.log_group_name
  retention_in_days = 14
  tags              = local.common_tags
}

# IAM
data "aws_iam_policy_document" "task_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "execution" {
  name               = "${local.name}-ecs-exec"
  assume_role_policy = data.aws_iam_policy_document.task_assume.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "execution" {
  role      = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task" {
  name               = "${local.name}-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.task_assume.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "task_policy" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [var.secret_arn]
  }
}

resource "aws_iam_role_policy" "task" {
  name   = "${local.name}-ecs-task-secrets"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.task_policy.json
}

# Security Group for tasks
resource "aws_security_group" "tasks" {
  name        = "${local.name}-sg-ecs"
  description = "ECS tasks SG"
  vpc_id      = var.vpc_id

  ingress {
    description     = "App traffic from ALB only"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name}-sg-ecs" })
}

# Target group
resource "aws_lb_target_group" "this" {
  name        = "${local.name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = var.health_check_path
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = merge(local.common_tags, { Name = "${local.name}-tg" })
}

# Listener on ALB (HTTP forward)
resource "aws_lb_listener" "http" {
  load_balancer_arn = var.alb_arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

# Task definition
locals {
  secret_env = [
    for k in var.secret_env_keys : {
      name      = k
      valueFrom = "${var.secret_arn}:${k}::"
    }
  ]
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${local.name}-${var.container_name}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.cpu)
  memory                   = tostring(var.memory)
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = var.image
      essential = true

      portMappings = [
        { containerPort = var.container_port, protocol = "tcp" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }

      secrets = local.secret_env
    }
  ])

  tags = local.common_tags
}

resource "aws_ecs_service" "this" {
  name            = "${local.name}-svc-${var.container_name}"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.app_subnet_ids
    security_groups  = [aws_security_group.tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener.http]
  tags       = local.common_tags
}
