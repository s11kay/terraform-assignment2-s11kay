# Example variables file
# Copy this file to terraform.tfvars and update with your values

aws_region         = "us-east-1"
environment        = "s11kay-dev"
availability_zone  = "us-east-1a"

# Backend configuration
state_bucket_name      = "s11-kay-state-bucket-12345-s11kay332439343"
state_lock_table_name  = "terraform-state-lock-s11kay2434"

# Network configuration
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidr   = "10.0.1.0/24"
private_subnet_cidr  = "10.0.2.0/24"

# S3 configuration
independent_bucket_name = "x11kayx11kay-bucket2434-s11kay123"

# EC2 configuration
key_name          = "my-EC2Keypair"
allowed_ssh_cidr  = "104.28.240.65/32"  # Replace with your IP
ami_id            = "ami-0532be01f26a3de55"  # Amazon Linux 2023 us-east-1
instance_type     = "t2.micro"
