variable "project_name" { type = string }
variable "environment"  { type = string }

variable "bucket_name" { type = string }

# Optional: custom domain
variable "domain_names" {
  type    = list(string)
  default = []
}

# Optional: ACM cert ARN (must be us-east-1 for CloudFront)
variable "acm_cert_arn_us_east_1" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
