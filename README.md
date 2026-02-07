# X11 Terraform Assignment - AWS Infrastructure

This project demonstrates secure AWS infrastructure deployment using Terraform modules with networking, security, and EC2 connectivity best practices.

## Architecture Overview

The infrastructure consists of:
- **VPC** with public and private subnets
- **Internet Gateway** for public subnet internet access
- **NAT Gateway** for private subnet outbound internet access
- **Bastion Host** (public EC2) for secure SSH access
- **Private EC2 Instance** accessible only through bastion
- **S3 Buckets** for Terraform state and independent storage
- **DynamoDB Table** for Terraform state locking

## Prerequisites

Before you begin, ensure you have:

1. **AWS Account** with appropriate permissions
2. **AWS CLI** installed and configured
   ```bash
   aws configure
   ```
3. **Terraform** installed (version >= 1.0)
   ```bash
   terraform --version
   ```
4. **SSH Key Pair** created in your AWS account
   ```bash
   aws ec2 create-key-pair --key-name x11-key --query 'KeyMaterial' --output text > x11-key.pem
   chmod 400 x11-key.pem
   ```
5. **Your Public IP Address**
   ```bash
   curl ifconfig.me
   ```

## Project Structure

```
.
├── main.tf                    # Main Terraform configuration
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output definitions
├── terraform.tfvars.example   # Example variables file
├── README.md                  # This file
├── SETUP_GUIDE.md            # Step-by-step setup instructions
└── modules/
    ├── backend/              # S3 + DynamoDB for state management
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── vpc/                  # VPC, subnets, IGW, NAT Gateway
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── s3/                   # Independent S3 bucket
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── ec2/                  # Bastion and private EC2 instances
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

