variable "project_name" { type = string }
variable "environment"  { type = string }

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "public_subnet_id" {
  type        = string
  description = "Public subnet to place EC2 in"
}

variable "admin_ssh_cidr" {
  type        = string
  description = "Your IPv4 CIDR for SSH (e.g., 76.36.87.39/32)"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "ami_id" {
  type        = string
  description = "Ubuntu AMI ID"
  default     = "ami-0ecb62995f68bb549"
}

variable "key_name" {
  type    = string
  default = "flightbooking-dev-key"
}

variable "private_key_filename" {
  type        = string
  description = "Where to save the generated .pem (relative to root module)"
  default     = "flightbooking-dev-key.pem"
}

variable "tags" {
  type    = map(string)
  default = {}
}
