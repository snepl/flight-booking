terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0"
    }
  }
}

provider "aws" {
  profile = "saroj-personal"
  region  = "us-east-1"

  default_tags {
    tags = {
      Project     = "flightbooking"
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}
