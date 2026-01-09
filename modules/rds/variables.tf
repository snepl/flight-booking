variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "db_subnet_ids" {
  type = list(string)
}

variable "allowed_sg_ids" {
  type        = list(string)
  description = "Security group IDs allowed to connect to Postgres (5432)"
}

variable "db_name" {
  type    = string
  default = "flightbooking"
}

variable "db_username" {
  type    = string
  default = "flightadmin"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "engine_version" {
  type    = string
  default = "16.4"
}

variable "tags" {
  type    = map(string)
  default = {}
}
