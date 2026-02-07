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

## Quick Start

### 1. Clone and Configure

```bash
# Copy the example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
# IMPORTANT: Update these values:
# - state_bucket_name (must be globally unique)
# - independent_bucket_name (must be globally unique)
# - key_name (your SSH key pair name)
# - allowed_ssh_cidr (your public IP/32)
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Review the Plan

```bash
terraform plan
```

### 4. Deploy Infrastructure

```bash
terraform apply
```

Type `yes` when prompted to confirm.

### 5. Configure Remote State (After First Apply)

After the initial deployment:

1. Uncomment the backend configuration in `main.tf`
2. Update the bucket name in the backend block
3. Migrate to remote state:
   ```bash
   terraform init -migrate-state
   ```

## Validation Steps

### Step 1: SSH into Bastion Host

```bash
# Get the bastion public IP from outputs
terraform output bastion_public_ip

# SSH into bastion
ssh -i /path/to/x11-key.pem ec2-user@<BASTION_PUBLIC_IP>
```

### Step 2: SSH from Bastion to Private Instance

```bash
# From your bastion host, get the private instance IP
# (You'll need to copy your private key to bastion or use SSH agent forwarding)

# Using SSH agent forwarding (recommended):
# Exit bastion first, then:
ssh-add /path/to/x11-key.pem
ssh -A -i /path/to/x11-key.pem ec2-user@<BASTION_PUBLIC_IP>

# Now from bastion:
ssh ec2-user@<PRIVATE_INSTANCE_IP>
```

### Step 3: Verify NAT Gateway Connectivity

```bash
# From the private instance, test internet access through NAT Gateway
sudo yum update -y

# Check outbound IP (should be NAT Gateway's Elastic IP, not private IP)
curl ifconfig.me
```

✅ **Success!** If `yum update` works, your NAT Gateway routing is configured correctly.

## Important Security Notes

### SSH Key Management
- **NEVER** commit your `.pem` private key files to version control
- Add `*.pem` to your `.gitignore`
- Set proper permissions: `chmod 400 your-key.pem`

### IP Address Updates
If your public IP changes:
```bash
# Update terraform.tfvars with new IP
allowed_ssh_cidr = "NEW.IP.ADDRESS/32"

# Apply changes
terraform apply
```

### Security Best Practices Implemented
- ✅ IMDSv2 enforced on all instances
- ✅ EBS volumes encrypted
- ✅ S3 buckets encrypted with versioning
- ✅ Public access blocked on S3 buckets
- ✅ Security groups follow least privilege
- ✅ Private instances have no public IPs

## Cost Awareness

**Important:** This infrastructure incurs AWS charges:
- **NAT Gateway**: ~$0.045/hour (~$32/month)
- **EC2 Instances**: t2.micro eligible for free tier
- **Elastic IP**: Free when attached, $0.005/hour when idle
- **S3 Storage**: Minimal cost for state files

### Cost Optimization
To avoid charges when not in use:
```bash
# Destroy all resources
terraform destroy
```

Type `yes` to confirm deletion of all resources.

## Troubleshooting

### Common Issues

**Issue: "bucket does not exist" when using remote backend**
- Solution: Deploy infrastructure first with local state, then migrate to remote state

**Issue: Can't SSH into bastion**
- Check your IP hasn't changed: `curl ifconfig.me`
- Verify security group allows your current IP
- Verify key permissions: `chmod 400 key.pem`

**Issue: Can't SSH from bastion to private instance**
- Use SSH agent forwarding: `ssh -A`
- Verify security group allows SSH from bastion security group
- Check instance IDs match: `terraform output`

**Issue: `yum update` fails on private instance**
- Verify NAT Gateway is in public subnet
- Check route table associations
- Verify private route table routes 0.0.0.0/0 to NAT Gateway

**Issue: "InvalidKeyPair.NotFound"**
- Verify key pair exists: `aws ec2 describe-key-pairs`
- Ensure key_name in terraform.tfvars matches AWS key pair name

## Outputs

After deployment, Terraform provides useful outputs:

```bash
terraform output
```

Key outputs:
- `bastion_public_ip` - Use this to SSH into bastion
- `private_instance_ip` - Use this to SSH from bastion to private instance
- `ssh_command_bastion` - Ready-to-use SSH command for bastion
- `ssh_command_private` - Ready-to-use SSH command for private instance

## Module Details

### Backend Module
- Creates S3 bucket with versioning and encryption
- Creates DynamoDB table for state locking
- Enables public access blocking on S3

### VPC Module
- Creates VPC with DNS support enabled
- Creates public subnet with auto-assign public IP
- Creates private subnet without public IP assignment
- Sets up Internet Gateway for public subnet
- Creates NAT Gateway with Elastic IP
- Configures route tables and associations

### S3 Module
- Creates independent S3 bucket
- Enables versioning and encryption
- Blocks all public access

### EC2 Module
- Creates bastion host in public subnet with public IP
- Creates private instance in private subnet (no public IP)
- Configures security groups with least privilege
- Enforces IMDSv2 and EBS encryption

## Cleanup

When you're done with the assignment:

```bash
# Destroy all resources
terraform destroy

# Verify all resources are deleted in AWS Console
# Note: S3 buckets must be empty to delete
```

## Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [Bastion Host Best Practices](https://aws.amazon.com/solutions/implementations/linux-bastion/)

## License

This is an educational project for X11 Terraform Assignment.
