variable "project_name" { type = string }
variable "environment"  { type = string }

variable "secret_name" {
  type        = string
  description = "Secrets Manager secret name"
}

variable "secret_json" {
  type        = string
  description = "JSON string to store in the secret"
}

variable "tags" {
  type    = map(string)
  default = {}
}
