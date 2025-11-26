# VPC CloudFormation Deployment Guide

This guide explains how to deploy the cost-optimized VPC CloudFormation template.

## Prerequisites

1. **AWS CLI installed** - [Installation Guide](https://aws.amazon.com/cli/)
2. **AWS credentials configured** - Run `aws configure`
3. **Appropriate IAM permissions** to create VPC resources

## Template Overview

The `vpc.yaml` template creates:
- ✅ 1 VPC (10.0.0.0/16)
- ✅ 2 Public Subnets (across 2 Availability Zones)
- ✅ 2 Private Subnets (across 2 Availability Zones)
- ✅ 1 Internet Gateway
- ✅ Route Tables
- ⚠️ NAT Gateway (optional - disabled by default to minimize costs)

**Cost:** $0/month (free tier eligible) when NAT Gateway is disabled

---

## Quick Start

### Option 1: Using PowerShell Script (Windows)

```powershell
# Basic deployment (free tier)
.\deploy-vpc.ps1

# With custom parameters
.\deploy-vpc.ps1 -StackName "dev-vpc" -Region "us-west-2" -EnvironmentName "Development"

# With NAT Gateway enabled
.\deploy-vpc.ps1 -EnableNATGateway "true" -EnvironmentName "Production"

# Validate template only
.\deploy-vpc.ps1 -Action validate

# Update existing stack
.\deploy-vpc.ps1 -Action update

# Delete stack
.\deploy-vpc.ps1 -Action delete
```

### Option 2: Direct AWS CLI Commands

#### Validate the template:
```bash
aws cloudformation validate-template \
  --template-body file://vpc.yaml \
  --region us-east-1
```

#### Create stack (free tier):
```bash
aws cloudformation create-stack \
  --stack-name my-vpc-stack \
  --template-body file://vpc.yaml \
  --region us-east-1 \
  --parameters \
    ParameterKey=EnableNATGateway,ParameterValue=false \
    ParameterKey=EnvironmentName,ParameterValue=Development
```

#### Create stack with NAT Gateway:
```bash
aws cloudformation create-stack \
  --stack-name my-vpc-stack \
  --template-body file://vpc.yaml \
  --region us-east-1 \
  --parameters \
    ParameterKey=EnableNATGateway,ParameterValue=true \
    ParameterKey=EnvironmentName,ParameterValue=Production
```

#### Monitor stack creation:
```bash
aws cloudformation wait stack-create-complete \
  --stack-name my-vpc-stack \
  --region us-east-1
```

#### Get stack outputs:
```bash
aws cloudformation describe-stacks \
  --stack-name my-vpc-stack \
  --region us-east-1 \
  --query 'Stacks[0].Outputs' \
  --output table
```

#### Update stack:
```bash
aws cloudformation update-stack \
  --stack-name my-vpc-stack \
  --template-body file://vpc.yaml \
  --region us-east-1 \
  --parameters \
    ParameterKey=EnableNATGateway,ParameterValue=true \
    ParameterKey=EnvironmentName,ParameterValue=Production
```

#### Delete stack:
```bash
aws cloudformation delete-stack \
  --stack-name my-vpc-stack \
  --region us-east-1
```

---

## Parameters

| Parameter | Description | Default | Valid Values |
|-----------|-------------|---------|--------------|
| `VpcCIDR` | CIDR block for the VPC | 10.0.0.0/16 | Valid CIDR notation |
| `PublicSubnet1CIDR` | CIDR for public subnet 1 | 10.0.1.0/24 | Valid CIDR notation |
| `PublicSubnet2CIDR` | CIDR for public subnet 2 | 10.0.2.0/24 | Valid CIDR notation |
| `PrivateSubnet1CIDR` | CIDR for private subnet 1 | 10.0.11.0/24 | Valid CIDR notation |
| `PrivateSubnet2CIDR` | CIDR for private subnet 2 | 10.0.12.0/24 | Valid CIDR notation |
| `EnvironmentName` | Environment tag | Development | Any string |
| `EnableNATGateway` | Enable NAT Gateway | false | true / false |

---

## Outputs

After successful deployment, the stack provides these outputs:

- **VPCId** - The VPC ID
- **VPCCidr** - The VPC CIDR block
- **PublicSubnets** - Comma-separated list of public subnet IDs
- **PrivateSubnets** - Comma-separated list of private subnet IDs
- **PublicSubnet1** - Public subnet 1 ID
- **PublicSubnet2** - Public subnet 2 ID
- **PrivateSubnet1** - Private subnet 1 ID
- **PrivateSubnet2** - Private subnet 2 ID
- **InternetGatewayId** - Internet Gateway ID
- **NatGatewayId** - NAT Gateway ID (only if enabled)
- **CostEstimate** - Estimated monthly cost

---

## Cost Considerations

### Free Tier Configuration (Default)
**Monthly Cost: $0**

Resources that are FREE:
- VPC
- Subnets
- Internet Gateway
- Route Tables
- Security Groups (default)

**Important:** Without NAT Gateway, "private" subnets route through the Internet Gateway. Use Security Groups to control access.

---

## Troubleshooting

### Stack creation fails
```bash
# View stack events
aws cloudformation describe-stack-events \
  --stack-name my-vpc-stack \
  --region us-east-1 \
  --max-items 20
```

### Check stack status
```bash
aws cloudformation describe-stacks \
  --stack-name my-vpc-stack \
  --region us-east-1 \
  --query 'Stacks[0].StackStatus'
```

### Insufficient permissions
Ensure your IAM user/role has these permissions:
- `ec2:*` (for VPC resources)
- `cloudformation:*` (for stack operations)
- `logs:*` (if enabling VPC Flow Logs in future)

### CIDR conflicts
If you get CIDR block conflicts, change the VPC CIDR:
```bash
--parameters ParameterKey=VpcCIDR,ParameterValue=172.16.0.0/16
```

---

## Next Steps
Deploy resources in the VPC

### Example: Launch EC2 in Public Subnet
```bash
# Get the subnet ID from outputs
SUBNET_ID=$(aws cloudformation describe-stacks \
  --stack-name my-vpc-stack \
  --query 'Stacks[0].Outputs[?OutputKey==`PublicSubnet1`].OutputValue' \
  --output text)

# Launch instance
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t2.micro \
  --subnet-id $SUBNET_ID \
  --associate-public-ip-address
```

## References

- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [CloudFormation VPC Resources](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-vpc.html)
- [AWS CLI Reference](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/)
- [VPC Pricing](https://aws.amazon.com/vpc/pricing/)
