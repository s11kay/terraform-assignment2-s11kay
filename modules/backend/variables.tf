# Backend Module Variables

variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
}

variable "state_lock_table_name" {
  description = "Name of the DynamoDB table for state locking"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}
