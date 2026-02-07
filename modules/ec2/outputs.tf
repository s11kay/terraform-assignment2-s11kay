# EC2 Module Outputs

output "bastion_instance_id" {
  description = "Instance ID of bastion host"
  value       = aws_instance.bastion.id
}

output "bastion_public_ip" {
  description = "Public IP of bastion host"
  value       = aws_instance.bastion.public_ip
}

output "bastion_private_ip" {
  description = "Private IP of bastion host"
  value       = aws_instance.bastion.private_ip
}

output "private_instance_id" {
  description = "Instance ID of private instance"
  value       = aws_instance.private.id
}

output "private_instance_ip" {
  description = "Private IP of private instance"
  value       = aws_instance.private.private_ip
}

output "bastion_security_group_id" {
  description = "Security group ID for bastion host"
  value       = aws_security_group.bastion.id
}

output "private_security_group_id" {
  description = "Security group ID for private instance"
  value       = aws_security_group.private.id
}
