# EC2 Web Server Template - Learning Project

This folder contains a CloudFormation template for deploying a free tier EC2 web server with Apache, serving a custom portfolio website hosted on S3.

## 📚 Learning Journey & Key Takeaways

This project demonstrates hands-on experience with AWS fundamentals, Infrastructure as Code, and troubleshooting real-world cloud deployment challenges.

### **What I Learned**

1. **CloudFormation Fundamentals**
   - Writing Infrastructure as Code (IaC) templates
   - Using parameters, conditions, and outputs
   - Cross-stack references with `Fn::ImportValue`
   - IAM roles and instance profiles
   - Resource dependencies and proper ordering

2. **EC2 Instance Management**
   - Free tier eligibility varies by region
   - User data scripts for automated configuration
   - Security group configuration for web traffic
   - Public vs private subnet deployment

3. **S3 Integration**
   - Static website hosting on S3
   - Bucket policies vs object ACLs
   - Public access configuration
   - IAM permissions for EC2 to access S3
   - CORS configuration for cross-origin requests

4. **Web Server Configuration**
   - Apache HTTP server installation and configuration
   - Serving static content
   - User data script execution on launch
   - Linux system administration basics

5. **Region-Specific Considerations**
   - Not all instance types are available in all regions
   - Free tier eligibility differs by region
   - Troubleshooting instance type compatibility

## 🔧 Critical Troubleshooting: Free Tier Instance Types

### **The Problem**
Received error: *"The specified instance type is not eligible for Free Tier"*

### **Root Cause**
Operating in a region region, which doesn't support older generation instance types like `t2.micro`.

### **Investigation Process**

**Step 1: Check what's actually free tier eligible**
```powershell
# List all free tier eligible instance types
aws ec2 describe-instance-types `
  --filters "Name=free-tier-eligible,Values=true" `
  --query "InstanceTypes[*].[InstanceType,VCpuInfo.DefaultVCpus,MemoryInfo.SizeInMiB]" `
  --output table
```

**Results for my region**
- ✅ t3.micro (2 vCPUs, 1024 MB) - Available
- ✅ t3.small (2 vCPUs, 2048 MB) - Available
- ✅ t4g.micro (2 vCPUs, 1024 MB, ARM) - Available
- ❌ t2.micro - **NOT available in this region**

### **Solution**
Changed default instance type from `t2.micro` to `t3.micro` for compatibility with eu-north-1.

### **Key Lesson**
Always verify instance type availability in your target region before deployment. Use AWS CLI to query available instance types rather than assuming.

## 📁 Folder Structure

```
EC2/
├── ec2-webserver.yaml    # CloudFormation template
├── index.html            # Custom HTML page (AI-generated with GitHub Copilot)
└── README.md            # This documentation
```

## 🎨 Website Design (index.html)

### **Creation Process**
The `index.html` file was created using **GitHub Copilot** with iterative prompts to achieve the desired look and functionality.

**Initial Prompt:**
> "Create a professional learning project portfolio page with dark background and pink accent colors"

**Refinement Prompts:**
- Changed color scheme from blue gradient to dark theme with pink accents
- Improved text visibility (changed black text to white on badges)
- Toned down bright link colors to softer pastels
- Added profile section with image
- Made responsive for mobile devices

### **Features Implemented**
- ✅ Dark theme (#0a0a0a background, #1a1a1a container)
- ✅ Pink color scheme (#ff1493 deep pink, #ff69b4 hot pink)
- ✅ High contrast for accessibility (WCAG AAA compliant)
- ✅ Real-time AWS instance metadata display
- ✅ Responsive design for all screen sizes
- ✅ Professional portfolio layout
- ✅ Animated elements (glow effects, hover states)

### **Potential Improvements**
Could be better but I am not a frontend developer. I have very limited knowledge on the subject.

## 🚀 Deployment Guide

### **Prerequisites**
1. AWS CLI installed and configured
2. VPC stack deployed (see `../vpc.yaml`)
3. S3 bucket created with your content
4. Profile image uploaded to S3

### **Step 1: Upload Content to S3**
```powershell
# Upload HTML page
aws s3 cp index.html s3://learning-on-aws-bucket-demo/ec2tutorials/index.html --acl public-read --content-type "text/html"

# Upload profile image
aws s3 cp profile.jpg s3://learning-on-aws-bucket-demo/ec2tutorials/img/profile.jpg --acl public-read
```

### **Step 2: Configure S3 Bucket Policy**
```powershell
aws s3api put-bucket-policy --bucket learning-on-aws-bucket-demo --policy '{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "PublicReadGetObject",
    "Effect": "Allow",
    "Principal": "*",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::learning-on-aws-bucket-demo/*"
  }]
}'
```

### **Step 3: Deploy EC2 Web Server**

```powershell
# Option 1: Using AWS Toolkit for VS Code (My preffered way)
# The AWS Toolkit streamlines validation and deployment with a visual interface

# 1. Right-click the template file and select "Deploy CloudFormation Stack"
```
![AWS Toolkit - Deploy CloudFormation Stack](./img/deploy-step1.png)

```powershell
# 2. Select your AWS region and S3 bucket for artifacts
```
![AWS Toolkit - Select Region and Bucket](./img/deploy-step2.png)

```powershell
# 3. Enter stack parameters when prompted (VPCStackName, KeyPairName, etc.)
```
![AWS Toolkit - Enter Parameters](./img/deploy-step3.png)

```powershell
# 4. Review the changeset and click "Deploy Changes"
```
![AWS Toolkit - Review Changeset](./img/deploy-step4.png)

```powershell
# 5. Monitor progress in the AWS Toolkit panel (Resources, Events, Outputs tabs)
```
![AWS Toolkit - Monitor Progress](./img/deploy-step5.png)

```powershell
# 6. Once complete, find the WebsiteURL in the Outputs tab
```
![AWS Toolkit - View Outputs](./img/deploy-step6.png)

```powershell
# Option 2: Using AWS CLI
aws cloudformation create-stack `
    --stack-name my-webserver `
    --template-body file://Cloudformation/EC2/ec2-webserver.yaml `
    --capabilities CAPABILITY_IAM `
    --parameters ParameterKey=VPCStackName,ParameterValue=my-vpc-stack `
    --region eu-north-1
```

**Note:** The AWS Toolkit provides a superior deployment experience with real-time validation, visual changeset review, and integrated stack management directly in VS Code. I am a fan and it has made my experience of AWS so much better

You can also visualize your infrastructure in VS Code (Check top right hand for an icon for Infrastructure Composer)
![alt text](image-7.png)

### **Step 4: Wait for Completion**
```powershell
aws cloudformation wait stack-create-complete --stack-name my-webserver
```

### **Step 5: Get Website URL**
```powershell
aws cloudformation describe-stacks `
  --stack-name my-webserver `
  --query 'Stacks[0].Outputs[?OutputKey==`WebsiteURL`].OutputValue' `
  --output text
```

## 📝 Architecture Overview

### **Content Flow**
1. **index.html** → Stored in S3 bucket
2. **profile.jpg** → Stored in S3 bucket  
3. **EC2 Instance** → Fetches content from S3 on launch
4. **Apache** → Serves content on port 80
5. **User** → Accesses via public IP/DNS

### **IAM Permissions**
The EC2 instance has an IAM role with:
- `s3:GetObject` - Download files from S3
- `s3:ListBucket` - List bucket contents
- `AmazonSSMManagedInstanceCore` - Session Manager access
- `CloudWatchAgentServerPolicy` - Metrics and logging

### **Security Configuration**
- **Port 80 (HTTP)**: Open to 0.0.0.0/0 (public web traffic)
- **Port 443 (HTTPS)**: Open to 0.0.0.0/0 (future SSL)
- **Port 22 (SSH)**: Configurable IP restriction
- **Outbound**: All traffic allowed (for updates and S3 access)

## 🎓 AWS Concepts Demonstrated

### **1. Infrastructure as Code (IaC)**
- Declarative configuration with CloudFormation
- Version control for infrastructure
- Repeatable, consistent deployments
- Parameter-driven templates

### **2. Compute Services**
- EC2 instance provisioning
- User data for automated configuration
- Instance profiles and IAM roles
- Free tier optimization

### **3. Storage Services**
- S3 for static content hosting
- Bucket policies
- Public access configuration
- Content delivery from S3

### **4. Networking**
- VPC and subnet configuration
- Security groups (stateful firewall)
- Public IP assignment
- Internet Gateway routing

### **5. Identity & Access Management**
- IAM roles for EC2
- Least privilege principle
- Service-linked roles
- Policy documents

## 🛠️ Troubleshooting Guide

### **Issue: Website Not Loading**

**Symptoms:** Cannot access website via public IP/DNS

**Diagnosis:**
```powershell
# 1. Check instance is running
aws ec2 describe-instances `
  --filters "Name=tag:aws:cloudformation:stack-name,Values=my-webserver" `
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]' `
  --output table

# 2. Check security group rules
aws ec2 describe-security-groups `
  --filters "Name=tag:aws:cloudformation:stack-name,Values=my-webserver" `
  --query 'SecurityGroups[*].IpPermissions[*].[FromPort,ToPort,IpRanges]'

# 3. Check user data execution
aws ssm start-session --target INSTANCE_ID
sudo cat /var/log/cloud-init-output.log
```

**Common Fixes:**
- Security group not allowing port 80
- Instance in private subnet without NAT Gateway
- Apache not started: `sudo systemctl start httpd`

### **Issue: S3 Content Not Loading**

**Symptoms:** Fallback page displays instead of actual content

**Diagnosis:**
```powershell
# Test S3 access from EC2
aws ssm start-session --target INSTANCE_ID
aws s3 ls s3://learning-on-aws-bucket-demo/ec2tutorials/
aws s3 cp s3://learning-on-aws-bucket-demo/ec2tutorials/index.html /tmp/test.html
```

**Common Fixes:**
- IAM role missing S3 permissions
- Bucket policy not allowing GetObject
- Incorrect S3 path in user data
- Region mismatch

### **Issue: Profile Image Not Displaying**

**Symptoms:** Image broken/not loading on website

**Diagnosis:**
```powershell
# Test image URL directly
curl -I https://learning-on-aws-bucket-demo.s3.amazonaws.com/ec2tutorials/img/profile.jpg

# Check object ACL
aws s3api get-object-acl `
  --bucket learning-on-aws-bucket-demo `
  --key ec2tutorials/img/profile.jpg
```

**Common Fixes:**
```powershell
# Set public-read ACL on image
aws s3api put-object-acl `
  --bucket learning-on-aws-bucket-demo `
  --key ec2tutorials/img/profile.jpg `
  --acl public-read

# Add CORS if needed
aws s3api put-bucket-cors `
  --bucket learning-on-aws-bucket-demo `
  --cors-configuration file://cors.json
```

## 🔄 Update Workflow

### **Update Website Content**
```powershell
# 1. Edit index.html locally
code Cloudformation/EC2/index.html

# 2. Upload to S3
aws s3 cp Cloudformation/EC2/index.html `
  s3://learning-on-aws-bucket-demo/ec2tutorials/index.html `
  --acl public-read `
  --content-type "text/html"

# 3. Update EC2 instance
aws ssm start-session --target INSTANCE_ID
cd /var/www/html
sudo aws s3 cp s3://learning-on-aws-bucket-demo/ec2tutorials/index.html index.html

# Changes are now live!
```

### **Update Profile Image**
```powershell
aws s3 cp new-profile.jpg `
  s3://learning-on-aws-bucket-demo/ec2tutorials/img/profile.jpg `
  --acl public-read
```

## 🗑️ Cleanup

### **Delete Stack**
```powershell
aws cloudformation delete-stack --stack-name my-webserver
aws cloudformation wait stack-delete-complete --stack-name my-webserver
```

### **Clean Up S3 (Optional)**
```powershell
aws s3 rm s3://learning-on-aws-bucket-demo/ec2tutorials/ --recursive
```

## 🎯 Key Takeaways

1. **Always verify instance type availability in your target region**
2. **Free tier eligibility varies by region and service**
3. **S3 bucket policies AND object ACLs must be configured for public access**
4. **IAM roles provide secure, credential-free access between services**
5. **User data scripts automate instance configuration and only run once at startup**
6. **Use SSM to execute scripts instead in enabling SSH access**
7. **CloudFormation enables reproducible infrastructure**
8. **AWS CLI is essential for troubleshooting and validation**

## 📚 Resources & References

- [AWS Free Tier](https://aws.amazon.com/free/)
- [EC2 Instance Types](https://aws.amazon.com/ec2/instance-types/)
- [CloudFormation Documentation](https://docs.aws.amazon.com/cloudformation/)
- [S3 Static Website Hosting](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)
- [IAM Roles for EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html)

---

**Project Status:** ✅ Complete and deployed
**Learning Focus:** AWS fundamentals, IaC, web hosting, troubleshooting
**Next Steps:** To be determined
