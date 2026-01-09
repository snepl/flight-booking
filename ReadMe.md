# FlightBooking Infrastructure – Terraform Guide

This repository provisions the FlightBooking infrastructure on AWS using Terraform.

## Architecture (Dev)

- VPC with public, app, and DB subnets (2 AZs)
- S3 for frontend (static site)
- CloudFront in front of S3
- ALB for backend traffic
- ECS Fargate for backend services
- RDS PostgreSQL (private subnets only)
- ECR for container images
- Secrets Manager for DB credentials
- CloudWatch Logs for ECS

## Repository Structure

```
.
├── modules/
│   ├── vpc/
│   ├── S3/
│   ├── cloudfront_s3/
│   ├── alb/
│   ├── ecs_fargate/
│   ├── rds/
│   ├── ecr/
│   └── secrets/
│
└── envs/
    └── dev/
        ├── backend.tf
        ├── provider.tf
        ├── main.tf
        ├── variables.tf
        └── terraform.tfvars
```

## Backend Configuration (State & Locking)

- State stored in S3
- S3 native locking enabled (no DynamoDB)

Example backend:

```hcl
terraform {
  backend "s3" {
    bucket  = "ramroflight-terraform-state-files-0"
    key     = "flightbooking/dev/terraform.tfstate"
    region  = "ap-south-1"
  }
}
```

## Where to Run Terraform Commands

⚠️ **Always run Terraform from the environment folder**

```bash
cd envs/dev
```

**Never run Terraform from:**
- repo root
- modules/
- nested module folders

## First-Time Setup

### 1. Initialize Terraform

```bash
terraform init -reconfigure
```

This will:
- configure S3 backend
- download providers
- load all modules

### 2. Format & Validate

```bash
terraform fmt -recursive
terraform validate
```

### 3. Plan Infrastructure

```bash
terraform plan
```

### 4. Apply Infrastructure

```bash
terraform apply
```

Confirm when prompted.

## Variables (terraform.tfvars – Dev)

```hcl
bucket_name            = "flightbooking-dev-frontend-s1"

backend_image          = "123456789012.dkr.ecr.ap-south-1.amazonaws.com/flight-booking-backend:latest"
backend_container_port = 8080
health_check_path      = "/health"

db_name     = "flightbooking"
db_username = "flightadmin"
db_password = "********"
```

⚠️ **Never reference modules or expressions in .tfvars**

## Secrets Handling (Important)

DB secrets are **NOT** hardcoded.

Secrets JSON is built dynamically in `envs/dev/main.tf`:

```hcl
locals {
  app_secret_json = jsonencode({
    DB_HOST = module.rds.endpoint
    DB_USER = var.db_username
    DB_PASS = var.db_password
    DB_NAME = var.db_name
  })
}
```

Passed to Secrets Manager:

```hcl
secret_json = local.app_secret_json
```

## State Lock Issues (S3 Locking)

If you see:

```
Error acquiring the state lock
```

**Fix:**

```bash
terraform force-unlock <LOCK_ID>
```

The correct lock ID is printed in the error message.

If needed:

```bash
aws s3 ls s3://ramroflight-terraform-state-files-0/flightbooking/dev/ --recursive
```

⚠️ Delete only `.tflock` / `.lock.info` if no Terraform is running.

## What Terraform Deploys

### Networking
- VPC
- Public / App / DB subnets
- IGW + NAT
- Route tables

### Frontend
- S3 bucket
- CloudFront distribution

### Backend
- ALB
- ECS cluster & service (Fargate)
- CloudWatch Logs

### Database
- RDS PostgreSQL (private)
- Security group restricted to ECS only

### Supporting
- ECR repositories
- Secrets Manager

## What Terraform Does NOT Do

You must still:
- Build & push Docker images to ECR
- Upload frontend build files to S3
- (Optional) Configure DNS + HTTPS certificates

## Adding New Environments (Future)

To add prod:

```
envs/
├── dev/
└── prod/
```

1. Copy dev → prod
2. Change backend key
3. Change variables
4. Run Terraform from `envs/prod`

## Notes & Best Practices

- Never edit `.terraform/` manually
- Never run Terraform in `modules/`
- Never put secrets directly in code
- Always use environment folders

