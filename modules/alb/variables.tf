variable "project_name" { type = string }
variable "environment"  { type = string }

variable "vpc_id" { type = string }

variable "public_subnet_ids" {
  type = list(string)
}

variable "listener_port" {
  type    = number
  default = 80
}

variable "tags" {
  type    = map(string)
  default = {}
}
