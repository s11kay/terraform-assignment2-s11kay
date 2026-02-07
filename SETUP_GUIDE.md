# X11 Terraform Assignment - Step-by-Step Setup Guide

This guide walks you through the complete setup process from scratch.

## Phase 1: Prerequisites Setup

### 1.1 Install Required Tools

#### Install AWS CLI
```bash
# macOS
brew install awscli

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Verify installation
aws --version
```

#### Install Terraform
```bash
# macOS
brew install terraform

# Linux
wget https://releases.hashicorp.com/terraform/1.7.0/terraform_1.7.0_linux_amd64.zip
unzip terraform_1.7.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Verify installation
terraform --version
```

### 1.2 Configure AWS Credentials

```bash
# Configure AWS CLI with your credentials
aws configure

# You'll be prompted for:
# AWS Access Key ID: [Enter your access key]
# AWS Secret Access Key: [Enter your secret key]
# Default region name: us-east-1
# Default output format: json

# Verify configuration
aws sts get-caller-identity
```

### 1.3 Create SSH Key Pair

```bash
# Create key pair in AWS
aws ec2 create-key-pair \
  --key-name x11-key \
  --query 'KeyMaterial' \
  --output text > ~/.ssh/x11-key.pem

# Set proper permissions
chmod 400 ~/.ssh/x11-key.pem

# Verify key pair was created
aws ec2 describe-key-pairs --key-names x11-key
```

### 1.4 Get Your Public IP

```bash
# Find your public IP address
curl ifconfig.me

# Note this IP - you'll need it for the allowed_ssh_cidr variable
```

## Phase 2: Project Setup

### 2.1 Prepare Configuration Files

```bash
# Navigate to project directory
cd terraform-x11-assignment

# Copy example variables file
cp terraform.tfvars.example terraform.tfvars
```

### 2.2 Edit terraform.tfvars

Open `terraform.tfvars` and update the following values:

```hcl
# Use your AWS region
aws_region = "us-east-1"

# IMPORTANT: S3 bucket names must be globally unique
# Replace with your own unique names
state_bucket_name       = "your-name-x11-terraform-state-2024"
independent_bucket_name = "your-name-x11-independent-bucket-2024"

# Use the key pair name you created
key_name = "x11-key"

# CRITICAL: Use your actual public IP from step 1.4
allowed_ssh_cidr = "YOUR.IP.ADDRESS/32"  # Example: "203.0.113.42/32"

# These can stay as defaults
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidr  = "10.0.1.0/24"
private_subnet_cidr = "10.0.2.0/24"
availability_zone   = "us-east-1a"
instance_type       = "t2.micro"
```

**Important Notes:**
- S3 bucket names must be globally unique across ALL AWS accounts
- Add your name or random numbers to ensure uniqueness
- The `/32` in allowed_ssh_cidr means "only this exact IP"

## Phase 3: Initial Deployment (Local State)

### 3.1 Initialize Terraform

```bash
# Initialize Terraform (downloads providers and modules)
terraform init
```

Expected output:
```
Initializing modules...
Initializing the backend...
Initializing provider plugins...
Terraform has been successfully initialized!
```

### 3.2 Validate Configuration

```bash
# Check for syntax errors
terraform validate
```

Expected output:
```
Success! The configuration is valid.
```

### 3.3 Format Code

```bash
# Format all .tf files
terraform fmt -recursive
```

### 3.4 Review Execution Plan

```bash
# See what Terraform will create
terraform plan
```

Review the output carefully. You should see:
- 1 VPC
- 2 Subnets (public and private)
- 1 Internet Gateway
- 1 NAT Gateway
- 1 Elastic IP
- 2 Route Tables
- 2 EC2 Instances
- 2 Security Groups
- 2 S3 Buckets
- 1 DynamoDB Table

Total: Approximately 20+ resources

### 3.5 Deploy Infrastructure

```bash
# Apply the configuration
terraform apply
```

- Review the plan one more time
- Type `yes` when prompted
- Wait 3-5 minutes for deployment

Expected output:
```
Apply complete! Resources: 20 added, 0 changed, 0 destroyed.

Outputs:
bastion_public_ip = "54.123.45.67"
private_instance_ip = "10.0.2.45"
...
```

**Save these outputs!** You'll need them for validation.

## Phase 4: Migrate to Remote State

### 4.1 Update main.tf

Edit `main.tf` and uncomment the backend configuration:

```hcl
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment this section:
  backend "s3" {
    bucket         = "your-name-x11-terraform-state-2024"  # Use your actual bucket name
    key            = "x11-assignment/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

### 4.2 Migrate State

```bash
# Re-initialize with new backend
terraform init -migrate-state
```

You'll be prompted:
```
Do you want to copy existing state to the new backend?
```

Type `yes` to migrate your local state to S3.

### 4.3 Verify Remote State

```bash
# Check S3 bucket for state file
aws s3 ls s3://your-name-x11-terraform-state-2024/x11-assignment/

# Verify DynamoDB table exists
aws dynamodb describe-table --table-name terraform-state-lock
```

## Phase 5: Validation Testing

### 5.1 Get Connection Information

```bash
# View all outputs
terraform output

# Get specific outputs
BASTION_IP=$(terraform output -raw bastion_public_ip)
PRIVATE_IP=$(terraform output -raw private_instance_ip)

echo "Bastion IP: $BASTION_IP"
echo "Private IP: $PRIVATE_IP"
```

### 5.2 Test SSH to Bastion Host

```bash
# SSH into bastion (from your local machine)
ssh -i ~/.ssh/x11-key.pem ec2-user@$BASTION_IP

# If successful, you should see:
# [ec2-user@ip-10-0-1-x ~]$
```

**Troubleshooting:**
- If connection times out: Check your IP hasn't changed (`curl ifconfig.me`)
- If "Permission denied": Check key permissions (`chmod 400 ~/.ssh/x11-key.pem`)
- If "Host key verification failed": Remove old host key or use `-o StrictHostKeyChecking=no`

### 5.3 Test SSH to Private Instance (Through Bastion)

#### Option A: SSH Agent Forwarding (Recommended)

```bash
# From your local machine
# Add key to SSH agent
ssh-add ~/.ssh/x11-key.pem

# SSH to bastion with agent forwarding
ssh -A -i ~/.ssh/x11-key.pem ec2-user@$BASTION_IP

# From bastion, SSH to private instance
ssh ec2-user@$PRIVATE_IP

# If successful, you should see:
# [ec2-user@ip-10-0-2-x ~]$
```

#### Option B: Copy Key to Bastion (Less Secure)

```bash
# From your local machine
# Copy key to bastion
scp -i ~/.ssh/x11-key.pem ~/.ssh/x11-key.pem ec2-user@$BASTION_IP:~/

# SSH to bastion
ssh -i ~/.ssh/x11-key.pem ec2-user@$BASTION_IP

# Set key permissions on bastion
chmod 400 ~/x11-key.pem

# SSH to private instance
ssh -i ~/x11-key.pem ec2-user@$PRIVATE_IP
```

### 5.4 Verify NAT Gateway Connectivity

```bash
# From the private instance
# Test internet connectivity through NAT Gateway
sudo yum update -y

# Check what IP is seen by external services
# This should show the NAT Gateway's Elastic IP, not the private IP
curl ifconfig.me

# Try installing a package to verify outbound connectivity
sudo yum install -y htop

# Check DNS resolution
nslookup google.com
```

**Expected Results:**
- ✅ `yum update` completes successfully
- ✅ `curl ifconfig.me` shows a public IP (NAT Gateway's Elastic IP)
- ✅ Package installation works
- ✅ DNS resolution works

### 5.5 Verify Security Group Rules

```bash
# From private instance, try to access internet directly
# This should work (via NAT Gateway)
ping -c 4 8.8.8.8

# From your local machine, try to SSH directly to private instance
# This should FAIL (timeout) - no public IP assigned
ssh -i ~/.ssh/x11-key.pem ec2-user@$PRIVATE_IP
# Expected: Connection timeout (this is correct behavior!)
```

## Phase 6: Verification Checklist

Mark each item as you verify:

- [ ] VPC created with correct CIDR block
- [ ] Public subnet has Internet Gateway route
- [ ] Private subnet has NAT Gateway route
- [ ] Bastion host has public IP
- [ ] Private instance has NO public IP
- [ ] Can SSH to bastion from local machine
- [ ] Can SSH to private instance from bastion
- [ ] `yum update` works on private instance
- [ ] Private instance accesses internet through NAT Gateway
- [ ] Cannot SSH directly to private instance from internet
- [ ] Remote state stored in S3
- [ ] State locking works (DynamoDB table has LockID attribute)

## Phase 7: Understanding Your Infrastructure

### 7.1 Examine VPC Components

```bash
# Get VPC ID
VPC_ID=$(terraform output -raw vpc_id)

# View VPC details
aws ec2 describe-vpcs --vpc-ids $VPC_ID

# View subnets
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID"

# View route tables
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID"

# View NAT Gateway
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID"
```

### 7.2 Examine Security Groups

```bash
# List security groups
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID"

# Check bastion security group rules
aws ec2 describe-security-groups \
  --filters "Name=tag:Name,Values=*bastion*" \
  --query 'SecurityGroups[0].IpPermissions'
```

### 7.3 View Terraform State

```bash
# List all resources in state
terraform state list

# Show specific resource
terraform state show module.vpc.aws_vpc.main

# Show outputs
terraform show
```

## Phase 8: Making Changes

### 8.1 Update Your Allowed IP (If Changed)

```bash
# Update terraform.tfvars with new IP
allowed_ssh_cidr = "NEW.IP.ADDRESS/32"

# Preview changes
terraform plan

# Apply changes
terraform apply
```

### 8.2 Change Instance Type

```bash
# Update terraform.tfvars
instance_type = "t3.micro"

# Apply changes
terraform apply
```

## Phase 9: Cleanup

### 9.1 Destroy Infrastructure

```bash
# Preview what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy
```

Type `yes` when prompted.

**Important:** This will delete:
- All EC2 instances
- NAT Gateway and Elastic IP
- VPC and all networking components
- DynamoDB table
- **BUT NOT** the S3 buckets (they must be empty first)

### 9.2 Delete S3 Buckets

```bash
# Empty and delete state bucket
aws s3 rm s3://your-name-x11-terraform-state-2024 --recursive
aws s3 rb s3://your-name-x11-terraform-state-2024

# Empty and delete independent bucket
aws s3 rm s3://your-name-x11-independent-bucket-2024 --recursive
aws s3 rb s3://your-name-x11-independent-bucket-2024
```

### 9.3 Delete SSH Key Pair

```bash
# Delete from AWS
aws ec2 delete-key-pair --key-name x11-key

# Delete local key file
rm ~/.ssh/x11-key.pem
```

## Troubleshooting Common Issues

### Issue: Terraform Init Fails

```bash
# Clear cached plugins
rm -rf .terraform
terraform init
```

### Issue: State Lock Error

```bash
# If state is locked and you're sure no one is using it
terraform force-unlock LOCK_ID
```

### Issue: Can't Destroy NAT Gateway

```bash
# NAT Gateway takes time to delete
# Wait 5-10 minutes and try again
terraform destroy
```

### Issue: Resource Already Exists

```bash
# Import existing resource
terraform import module.vpc.aws_vpc.main vpc-xxxxxxxx
```

## Next Steps

After completing this assignment, consider:

1. **Add Monitoring**: Implement CloudWatch alarms
2. **Multi-AZ**: Extend to multiple availability zones
3. **Auto Scaling**: Replace single instances with ASGs
4. **Load Balancer**: Add an Application Load Balancer
5. **VPC Endpoints**: Reduce NAT Gateway costs for AWS services
6. **Systems Manager**: Replace bastion with SSM Session Manager

## Estimated Costs

- **NAT Gateway**: $32-35/month (even if idle)
- **EC2 t2.micro**: Free tier eligible (first 750 hours/month)
- **Elastic IP**: Free when attached
- **S3**: <$1/month for state files
- **DynamoDB**: Free tier eligible

**Total monthly cost**: ~$32-36 if left running

## Conclusion

You have successfully:
- ✅ Deployed a production-grade VPC architecture
- ✅ Implemented bastion host security pattern
- ✅ Configured NAT Gateway for private subnet internet access
- ✅ Used Terraform modules for code organization
- ✅ Implemented remote state with locking
- ✅ Validated connectivity end-to-end

Congratulations on completing the X11 Terraform Assignment!
