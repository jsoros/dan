#!/bin/bash
# Deployment script for AZ Health Check Lambda Function

set -e

# Configuration
FUNCTION_NAME="${FUNCTION_NAME:-az-health-check}"
REGION="${AWS_REGION:-us-east-1}"
STACK_NAME="${STACK_NAME:-az-health-check-stack}"

echo "=========================================="
echo "AZ Health Check Lambda Deployment"
echo "=========================================="
echo "Function Name: $FUNCTION_NAME"
echo "Region: $REGION"
echo "Stack Name: $STACK_NAME"
echo "=========================================="

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

echo "✓ AWS CLI configured"

# Create deployment package
echo ""
echo "Creating deployment package..."
if [ -f function.zip ]; then
    rm function.zip
fi

zip -q function.zip lambda_function.py
echo "✓ Deployment package created: function.zip"

# Check if CloudFormation stack exists
STACK_EXISTS=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    2>&1 | grep -c "does not exist" || true)

if [ "$STACK_EXISTS" -eq 1 ]; then
    echo ""
    echo "Creating new CloudFormation stack..."
    aws cloudformation create-stack \
        --stack-name "$STACK_NAME" \
        --template-body file://cloudformation-template.yaml \
        --parameters ParameterKey=FunctionName,ParameterValue="$FUNCTION_NAME" \
        --capabilities CAPABILITY_NAMED_IAM \
        --region "$REGION"

    echo "Waiting for stack creation to complete..."
    aws cloudformation wait stack-create-complete \
        --stack-name "$STACK_NAME" \
        --region "$REGION"

    echo "✓ Stack created successfully"
else
    echo ""
    echo "Updating existing CloudFormation stack..."
    aws cloudformation update-stack \
        --stack-name "$STACK_NAME" \
        --template-body file://cloudformation-template.yaml \
        --parameters ParameterKey=FunctionName,ParameterValue="$FUNCTION_NAME" \
        --capabilities CAPABILITY_NAMED_IAM \
        --region "$REGION" || true

    echo "Waiting for stack update to complete..."
    aws cloudformation wait stack-update-complete \
        --stack-name "$STACK_NAME" \
        --region "$REGION" 2>/dev/null || true

    echo "✓ Stack updated successfully"
fi

# Update function code
echo ""
echo "Updating Lambda function code..."
aws lambda update-function-code \
    --function-name "$FUNCTION_NAME" \
    --zip-file fileb://function.zip \
    --region "$REGION" > /dev/null

echo "✓ Function code updated"

# Get function ARN
FUNCTION_ARN=$(aws lambda get-function \
    --function-name "$FUNCTION_NAME" \
    --region "$REGION" \
    --query 'Configuration.FunctionArn' \
    --output text)

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo "Function ARN: $FUNCTION_ARN"
echo ""
echo "Test the function with:"
echo "aws lambda invoke \\"
echo "  --function-name $FUNCTION_NAME \\"
echo "  --payload file://test-event.json \\"
echo "  --region $REGION \\"
echo "  response.json"
echo ""
echo "cat response.json | jq ."
echo "=========================================="
