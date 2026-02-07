# Outputs for X11 Terraform Assignment

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = module.vpc.public_subnet_id
}

output "private_subnet_id" {
  description = "Private subnet ID"
  value       = module.vpc.private_subnet_id
}

output "bastion_public_ip" {
  description = "Public IP of bastion host"
  value       = module.ec2.bastion_public_ip
}

output "bastion_instance_id" {
  description = "Instance ID of bastion host"
  value       = module.ec2.bastion_instance_id
}

output "private_instance_ip" {
  description = "Private IP of private EC2 instance"
  value       = module.ec2.private_instance_ip
}

output "private_instance_id" {
  description = "Instance ID of private EC2 instance"
  value       = module.ec2.private_instance_id
}

output "independent_bucket_name" {
  description = "Name of independent S3 bucket"
  value       = module.s3.bucket_name
}

output "state_bucket_name" {
  description = "Name of Terraform state S3 bucket"
  value       = module.backend.state_bucket_name
}

output "ssh_command_bastion" {
  description = "SSH command to connect to bastion host"
  value       = "ssh -i /path/to/your-key.pem ec2-user@${module.ec2.bastion_public_ip}"
}

output "ssh_command_private" {
  description = "SSH command to connect to private instance from bastion"
  value       = "ssh -i /path/to/your-key.pem ec2-user@${module.ec2.private_instance_ip}"
}
