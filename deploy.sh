#!/bin/bash
# Deployment script for AZ Health Check Lambda Function using Terraform

set -e

# Configuration
TERRAFORM_DIR="terraform"
FUNCTION_NAME="${FUNCTION_NAME:-az-health-check}"
REGION="${AWS_REGION:-us-east-1}"

echo "=========================================="
echo "AZ Health Check Lambda Deployment"
echo "=========================================="
echo "Function Name: $FUNCTION_NAME"
echo "Region: $REGION"
echo "Terraform Dir: $TERRAFORM_DIR"
echo "=========================================="

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "ERROR: Terraform is not installed"
    echo "Install from: https://www.terraform.io/downloads"
    exit 1
fi

echo "✓ Terraform installed ($(terraform version -json | grep -o '"terraform_version":"[^"]*' | cut -d'"' -f4))"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "ERROR: AWS CLI is not installed"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "ERROR: AWS credentials not configured"
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "✓ AWS credentials configured (Account: $ACCOUNT_ID)"

# Navigate to Terraform directory
cd "$TERRAFORM_DIR"

# Initialize Terraform if not already done
if [ ! -d ".terraform" ]; then
    echo ""
    echo "Initializing Terraform..."
    terraform init
    echo "✓ Terraform initialized"
else
    echo ""
    echo "Terraform already initialized"
fi

# Create terraform.tfvars if it doesn't exist
if [ ! -f "terraform.tfvars" ]; then
    echo ""
    echo "Creating terraform.tfvars from example..."
    cat > terraform.tfvars <<EOF
function_name      = "$FUNCTION_NAME"
aws_region        = "$REGION"
lambda_timeout    = 30
lambda_memory_size = 256
log_retention_days = 7

tags = {
  Name        = "$FUNCTION_NAME"
  Purpose     = "AZ Health Monitoring"
  ManagedBy   = "Terraform"
}
EOF
    echo "✓ Created terraform.tfvars"
fi

# Validate Terraform configuration
echo ""
echo "Validating Terraform configuration..."
terraform validate
echo "✓ Configuration is valid"

# Show Terraform plan
echo ""
echo "Planning Terraform changes..."
terraform plan -out=tfplan

# Ask for confirmation
echo ""
read -p "Apply these changes? (yes/no): " -r
echo
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Deployment cancelled"
    rm -f tfplan
    exit 0
fi

# Apply Terraform configuration
echo ""
echo "Applying Terraform configuration..."
terraform apply tfplan
rm -f tfplan

# Get outputs
echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="

FUNCTION_ARN=$(terraform output -raw function_arn)
FUNCTION_NAME=$(terraform output -raw function_name)
LOG_GROUP=$(terraform output -raw log_group_name)

echo "Function Name: $FUNCTION_NAME"
echo "Function ARN:  $FUNCTION_ARN"
echo "Log Group:     $LOG_GROUP"
echo ""
echo "Test the function with:"
terraform output -raw invoke_command
echo ""
echo ""
echo "Or use the test event file:"
echo "aws lambda invoke \\"
echo "  --function-name $FUNCTION_NAME \\"
echo "  --payload file://../test-event.json \\"
echo "  response.json && cat response.json | jq ."
echo ""
echo "View logs:"
echo "aws logs tail $LOG_GROUP --follow"
echo "=========================================="
