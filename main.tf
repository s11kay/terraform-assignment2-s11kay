# Main Terraform Configuration
# This file orchestrates all modules

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend configuration - uncomment after initial setup
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "x11-assignment/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region
}

# Backend Module - Creates S3 and DynamoDB for state management
module "backend" {
  source = "./modules/backend"
  
  state_bucket_name      = var.state_bucket_name
  state_lock_table_name  = var.state_lock_table_name
  environment            = var.environment
}

# VPC Module - Creates networking infrastructure
module "vpc" {
  source = "./modules/vpc"
  
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidr   = var.public_subnet_cidr
  private_subnet_cidr  = var.private_subnet_cidr
  availability_zone    = var.availability_zone
  environment          = var.environment
}

# S3 Module - Creates independent S3 bucket
module "s3" {
  source = "./modules/s3"
  
  bucket_name = var.independent_bucket_name
  environment = var.environment
}

# EC2 Module - Creates public and private EC2 instances
module "ec2" {
  source = "./modules/ec2"
  
  vpc_id                = module.vpc.vpc_id
  public_subnet_id      = module.vpc.public_subnet_id
  private_subnet_id     = module.vpc.private_subnet_id
  key_name              = var.key_name
  allowed_ssh_cidr      = var.allowed_ssh_cidr
  ami_id                = var.ami_id
  instance_type         = var.instance_type
  environment           = var.environment
}
