variable "aws_region" {
  description = "AWS region for ECS logs"
  type        = string
}


variable "project_name" { type = string }
variable "environment"  { type = string }

variable "vpc_id" { type = string }
variable "app_subnet_ids" { type = list(string) }

variable "alb_arn" { type = string }
variable "alb_sg_id" { type = string }

variable "container_name" { type = string }
variable "container_port" { type = number }

variable "image" {
  type        = string
  description = "ECR image URI with tag (e.g., <repo>:latest)"
}

variable "desired_count" {
  type    = number
  default = 2
}

variable "cpu" {
  type    = number
  default = 512
}

variable "memory" {
  type    = number
  default = 1024
}

variable "secret_arn" {
  type        = string
  description = "Secrets Manager secret ARN (JSON). ECS will read keys via environment variables if you map them."
}

variable "secret_env_keys" {
  type        = list(string)
  description = "List of keys inside the JSON secret to inject as env vars"
  default     = []
}

variable "health_check_path" {
  type    = string
  default = "/health"
}

variable "tags" {
  type    = map(string)
  default = {}
}
