variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name"
  type        = string
}

variable "force_destroy" {
  description = "Allow deleting bucket with objects (dev only)"
  type        = bool
  default     = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
