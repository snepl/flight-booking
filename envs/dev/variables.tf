variable "backend_image" {
  type        = string
  description = "ECR image URI with tag, e.g. <acct>.dkr.ecr.us-east-1.amazonaws.com/flight-booking-backend:latest"
}

variable "backend_container_port" {
  type        = number
  description = "Container port exposed by the backend service"
  default     = 8080
}

variable "health_check_path" {
  type        = string
  description = "ALB health check path for the backend"
  default     = "/health"
}

variable "secret_env_keys" {
  type        = list(string)
  description = "Keys inside secret JSON to inject into ECS container as env vars"
  default     = ["DB_HOST", "DB_USER", "DB_PASS", "DB_NAME"]
}

variable "db_name" {
  type        = string
  description = "RDS database name"
}

variable "db_username" {
  type        = string
  description = "RDS master username"
}

variable "db_password" {
  type        = string
  description = "RDS master password"
  sensitive   = true
}

variable "bucket_name" {
  type        = string
  description = "Frontend S3 bucket name"
}
