variable "project_name" {
  description = "Project name (e.g., flightbooking)"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "repositories" {
  description = "List of ECR repository names to create"
  type        = list(string)
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
