#!/bin/bash

# X11 Terraform Assignment - Validation Script
# This script helps validate that the infrastructure is correctly deployed

set -e

echo "================================================"
echo "X11 Terraform Assignment - Validation Script"
echo "================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
    fi
}

# Check if terraform is initialized
echo "Step 1: Checking Terraform initialization..."
if [ -d ".terraform" ]; then
    print_status 0 "Terraform is initialized"
else
    print_status 1 "Terraform not initialized. Run: terraform init"
    exit 1
fi

# Check if state exists
echo ""
echo "Step 2: Checking Terraform state..."
if terraform show &> /dev/null; then
    print_status 0 "Terraform state exists"
else
    print_status 1 "No Terraform state found. Run: terraform apply"
    exit 1
fi

# Get outputs
echo ""
echo "Step 3: Retrieving infrastructure details..."
BASTION_IP=$(terraform output -raw bastion_public_ip 2>/dev/null)
PRIVATE_IP=$(terraform output -raw private_instance_ip 2>/dev/null)
VPC_ID=$(terraform output -raw vpc_id 2>/dev/null)

if [ -z "$BASTION_IP" ] || [ -z "$PRIVATE_IP" ] || [ -z "$VPC_ID" ]; then
    print_status 1 "Failed to retrieve outputs"
    exit 1
fi

print_status 0 "Retrieved infrastructure details"
echo "   Bastion IP: $BASTION_IP"
echo "   Private IP: $PRIVATE_IP"
echo "   VPC ID: $VPC_ID"

# Check if bastion is reachable
echo ""
echo "Step 4: Testing bastion host connectivity..."
echo -e "${YELLOW}Note: This assumes your SSH key is at ~/.ssh/x11-key.pem${NC}"
echo "Testing SSH connectivity to bastion (timeout: 5 seconds)..."

if timeout 5 ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -i ~/.ssh/x11-key.pem ec2-user@$BASTION_IP "echo 'SSH successful'" &> /dev/null; then
    print_status 0 "Bastion host is reachable via SSH"
else
    print_status 1 "Cannot connect to bastion host"
    echo -e "${YELLOW}Possible issues:${NC}"
    echo "   - Your IP address may have changed"
    echo "   - Security group may not allow your current IP"
    echo "   - SSH key path may be incorrect"
    echo "   - Instance may still be initializing"
fi

# Verify VPC resources
echo ""
echo "Step 5: Verifying VPC resources..."

# Check subnets
SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[*].SubnetId' --output text | wc -w)
if [ "$SUBNETS" -eq 2 ]; then
    print_status 0 "VPC has 2 subnets (public and private)"
else
    print_status 1 "VPC should have 2 subnets, found: $SUBNETS"
fi

# Check Internet Gateway
IGW=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[*].InternetGatewayId' --output text)
if [ -n "$IGW" ]; then
    print_status 0 "Internet Gateway exists and is attached"
else
    print_status 1 "No Internet Gateway found"
fi

# Check NAT Gateway
NAT=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" "Name=state,Values=available" --query 'NatGateways[*].NatGatewayId' --output text)
if [ -n "$NAT" ]; then
    print_status 0 "NAT Gateway exists and is available"
else
    print_status 1 "No NAT Gateway found or not available"
fi

# Check EC2 instances
echo ""
echo "Step 6: Verifying EC2 instances..."

INSTANCES=$(aws ec2 describe-instances --filters "Name=vpc-id,Values=$VPC_ID" "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].InstanceId' --output text | wc -w)
if [ "$INSTANCES" -eq 2 ]; then
    print_status 0 "Found 2 running EC2 instances"
else
    print_status 1 "Expected 2 EC2 instances, found: $INSTANCES"
fi

# Check public IP assignment
PUBLIC_INSTANCE=$(aws ec2 describe-instances --filters "Name=vpc-id,Values=$VPC_ID" "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[?PublicIpAddress!=`null`]' --output json | jq '. | length')
if [ "$PUBLIC_INSTANCE" -eq 1 ]; then
    print_status 0 "Bastion has public IP, private instance has no public IP"
else
    print_status 1 "Public IP assignment incorrect"
fi

# Summary
echo ""
echo "================================================"
echo "Validation Summary"
echo "================================================"
echo ""
echo "To complete validation, perform these manual tests:"
echo ""
echo "1. SSH to bastion host:"
echo "   ssh -i ~/.ssh/x11-key.pem ec2-user@$BASTION_IP"
echo ""
echo "2. From bastion, SSH to private instance:"
echo "   ssh -A -i ~/.ssh/x11-key.pem ec2-user@$BASTION_IP"
echo "   Then: ssh ec2-user@$PRIVATE_IP"
echo ""
echo "3. On private instance, test NAT Gateway:"
echo "   sudo yum update -y"
echo "   curl ifconfig.me"
echo ""
echo "If all tests pass, your infrastructure is correctly configured!"
echo "================================================"
