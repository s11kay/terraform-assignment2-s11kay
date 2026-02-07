
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

