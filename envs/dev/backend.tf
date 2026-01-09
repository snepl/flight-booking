terraform {
  backend "s3" {
    bucket       = "ramroflight-terraform-state-files-0"
    key          = "flightbooking/dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
    profile      = "saroj-personal"
  }
}
