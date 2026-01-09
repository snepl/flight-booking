locals {
  app_secret_json = jsonencode({
    DB_HOST = module.rds.endpoint
    DB_USER = var.db_username
    DB_PASS = var.db_password
    DB_NAME = var.db_name
  })
}

module "vpc" {
  source = "../../modules/vpc"

  project_name = "flightbooking"
  environment  = "dev"

  vpc_cidr           = "10.20.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]

  public_subnet_cidrs = ["10.20.1.0/24", "10.20.2.0/24"]
  app_subnet_cidrs    = ["10.20.11.0/24", "10.20.12.0/24"]
  db_subnet_cidrs     = ["10.20.21.0/24", "10.20.22.0/24"]

  single_nat_gateway = false
}

module "frontend_s3" {
  source = "../../modules/S3"

  project_name = "flightbooking"
  environment  = "dev"

  bucket_name   = var.bucket_name
  force_destroy = false
}



module "ecr" {
  source = "../../modules/ecr"

  project_name = "flightbooking"
  environment  = "dev"

  repositories = [
    "flight-booking-backend",
  ]
}

module "secrets" {
  source = "../../modules/secrets"

  project_name = "flightbooking"
  environment  = "dev"

  secret_name = "flight-booking/dev/config"
  secret_json = local.app_secret_json
}

module "alb" {
  source = "../../modules/alb"

  project_name = "flightbooking"
  environment  = "dev"

  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
}

module "ecs_backend" {
  source     = "../../modules/ecs_fargate"
  aws_region = "us-east-1"

  project_name = "flightbooking"
  environment  = "dev"

  vpc_id         = module.vpc.vpc_id
  app_subnet_ids = module.vpc.app_subnet_ids

  alb_arn   = module.alb.alb_arn
  alb_sg_id = module.alb.alb_sg_id

  container_name = "backend"
  container_port = var.backend_container_port

  image         = var.backend_image
  desired_count = 2

  secret_arn      = module.secrets.secret_arn
  secret_env_keys = var.secret_env_keys

  health_check_path = var.health_check_path
}

module "rds" {
  source = "../../modules/rds"

  project_name = "flightbooking"
  environment  = "dev"

  vpc_id        = module.vpc.vpc_id
  db_subnet_ids = module.vpc.db_subnet_ids

  allowed_sg_ids = [module.ecs_backend.tasks_sg_id]

  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
}

module "cloudfront_frontend" {
  source = "../../modules/cloudfront_s3"

  project_name = "flightbooking"
  environment  = "dev"

  bucket_name = module.frontend_s3.bucket_name

  # optional for now
  domain_names           = []
  acm_cert_arn_us_east_1 = ""
}
