variable "project_name" {
  description = "Project name (e.g., flightbooking)"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev)"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "availability_zones" {
  description = "Exactly two availability zones"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) == 2
    error_message = "This module requires exactly 2 availability zones."
  }
}

variable "public_subnet_cidrs" {
  description = "Public (web) subnet CIDRs (must match AZ count)"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) == length(var.availability_zones)
    error_message = "public_subnet_cidrs must match availability_zones (2)."
  }
}

variable "app_subnet_cidrs" {
  description = "Private application subnet CIDRs (must match AZ count)"
  type        = list(string)

  validation {
    condition     = length(var.app_subnet_cidrs) == length(var.availability_zones)
    error_message = "app_subnet_cidrs must match availability_zones (2)."
  }
}

variable "db_subnet_cidrs" {
  description = "Private database subnet CIDRs (must match AZ count)"
  type        = list(string)

  validation {
    condition     = length(var.db_subnet_cidrs) == length(var.availability_zones)
    error_message = "db_subnet_cidrs must match availability_zones (2)."
  }
}

variable "single_nat_gateway" {
  description = "If true, create one NAT Gateway in public subnet 1. If false, one NAT per AZ."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Extra tags to apply to all resources"
  type        = map(string)
  default     = {}
}
