# CloudFormation VPC Deployment Script (PowerShell)
# This script deploys the VPC CloudFormation template with various options

param(
    [Parameter(Mandatory=$false)]
    [string]$StackName = "my-vpc-stack",
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-east-1",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("true", "false")]
    [string]$EnableNATGateway = "false",
    
    [Parameter(Mandatory=$false)]
    [string]$EnvironmentName = "Development",
    
    [Parameter(Mandatory=$false)]
    [string]$VpcCIDR = "10.0.0.0/16",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("create", "update", "delete", "validate")]
    [string]$Action = "create"
)

$TemplateFile = "$PSScriptRoot\vpc.yaml"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "CloudFormation VPC Deployment Script" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Check if AWS CLI is installed
try {
    $awsVersion = aws --version 2>&1
    Write-Host "✓ AWS CLI detected: $awsVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ AWS CLI not found. Please install: https://aws.amazon.com/cli/" -ForegroundColor Red
    exit 1
}

# Check if template file exists
if (-not (Test-Path $TemplateFile)) {
    Write-Host "✗ Template file not found: $TemplateFile" -ForegroundColor Red
    exit 1
}

Write-Host "Template File: $TemplateFile" -ForegroundColor Yellow
Write-Host "Stack Name: $StackName" -ForegroundColor Yellow
Write-Host "Region: $Region" -ForegroundColor Yellow
Write-Host "Environment: $EnvironmentName" -ForegroundColor Yellow
Write-Host "NAT Gateway: $EnableNATGateway" -ForegroundColor Yellow
Write-Host ""

switch ($Action) {
    "validate" {
        Write-Host "Validating CloudFormation template..." -ForegroundColor Cyan
        aws cloudformation validate-template `
            --template-body file://$TemplateFile `
            --region $Region
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Template is valid!" -ForegroundColor Green
        } else {
            Write-Host "✗ Template validation failed!" -ForegroundColor Red
            exit 1
        }
    }
    
    "create" {
        Write-Host "Creating CloudFormation stack..." -ForegroundColor Cyan
        Write-Host ""
        
        # Validate first
        Write-Host "Step 1: Validating template..." -ForegroundColor Yellow
        aws cloudformation validate-template `
            --template-body file://$TemplateFile `
            --region $Region --no-cli-pager
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "✗ Template validation failed!" -ForegroundColor Red
            exit 1
        }
        Write-Host "✓ Template validated successfully" -ForegroundColor Green
        Write-Host ""
        
        # Create stack
        Write-Host "Step 2: Creating stack '$StackName'..." -ForegroundColor Yellow
        aws cloudformation create-stack `
            --stack-name $StackName `
            --template-body file://$TemplateFile `
            --region $Region `
            --parameters `
                ParameterKey=EnableNATGateway,ParameterValue=$EnableNATGateway `
                ParameterKey=EnvironmentName,ParameterValue=$EnvironmentName `
                ParameterKey=VpcCIDR,ParameterValue=$VpcCIDR `
            --tags `
                Key=ManagedBy,Value=CloudFormation `
                Key=Environment,Value=$EnvironmentName `
            --no-cli-pager
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Stack creation initiated!" -ForegroundColor Green
            Write-Host ""
            Write-Host "Waiting for stack creation to complete..." -ForegroundColor Cyan
            Write-Host "(This typically takes 2-3 minutes)" -ForegroundColor Gray
            Write-Host ""
            
            aws cloudformation wait stack-create-complete `
                --stack-name $StackName `
                --region $Region
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✓ Stack created successfully!" -ForegroundColor Green
                Write-Host ""
                Write-Host "Fetching stack outputs..." -ForegroundColor Cyan
                aws cloudformation describe-stacks `
                    --stack-name $StackName `
                    --region $Region `
                    --query 'Stacks[0].Outputs' `
                    --output table
            } else {
                Write-Host "✗ Stack creation failed or timed out" -ForegroundColor Red
                Write-Host "Check events for details:" -ForegroundColor Yellow
                Write-Host "aws cloudformation describe-stack-events --stack-name $StackName --region $Region" -ForegroundColor Gray
                exit 1
            }
        } else {
            Write-Host "✗ Failed to initiate stack creation!" -ForegroundColor Red
            exit 1
        }
    }
    
    "update" {
        Write-Host "Updating CloudFormation stack..." -ForegroundColor Cyan
        Write-Host ""
        
        aws cloudformation update-stack `
            --stack-name $StackName `
            --template-body file://$TemplateFile `
            --region $Region `
            --parameters `
                ParameterKey=EnableNATGateway,ParameterValue=$EnableNATGateway `
                ParameterKey=EnvironmentName,ParameterValue=$EnvironmentName `
                ParameterKey=VpcCIDR,ParameterValue=$VpcCIDR `
            --no-cli-pager
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Stack update initiated!" -ForegroundColor Green
            Write-Host ""
            Write-Host "Waiting for stack update to complete..." -ForegroundColor Cyan
            
            aws cloudformation wait stack-update-complete `
                --stack-name $StackName `
                --region $Region
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✓ Stack updated successfully!" -ForegroundColor Green
            } else {
                Write-Host "✗ Stack update failed or timed out" -ForegroundColor Red
                exit 1
            }
        } else {
            Write-Host "Note: This might mean no updates are needed" -ForegroundColor Yellow
        }
    }
    
    "delete" {
        Write-Host "WARNING: This will delete the stack and all resources!" -ForegroundColor Red
        $confirmation = Read-Host "Type 'yes' to confirm deletion of stack '$StackName'"
        
        if ($confirmation -eq "yes") {
            Write-Host "Deleting CloudFormation stack..." -ForegroundColor Cyan
            
            aws cloudformation delete-stack `
                --stack-name $StackName `
                --region $Region
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✓ Stack deletion initiated!" -ForegroundColor Green
                Write-Host ""
                Write-Host "Waiting for stack deletion to complete..." -ForegroundColor Cyan
                
                aws cloudformation wait stack-delete-complete `
                    --stack-name $StackName `
                    --region $Region
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✓ Stack deleted successfully!" -ForegroundColor Green
                } else {
                    Write-Host "✗ Stack deletion failed or timed out" -ForegroundColor Red
                    exit 1
                }
            } else {
                Write-Host "✗ Failed to initiate stack deletion!" -ForegroundColor Red
                exit 1
            }
        } else {
            Write-Host "Deletion cancelled." -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Operation completed!" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
