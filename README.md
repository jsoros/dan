# AWS Availability Zone Health Check Lambda

A Lambda function that determines if an AWS Availability Zone is experiencing issues by checking AWS Health API and EC2 status.

## Features

- **Health API Integration**: Queries AWS Health API for AZ-specific events and incidents
- **EC2 Status Monitoring**: Checks AZ state and availability through EC2 API
- **Severity Classification**: Categorizes issues as healthy, degraded, or unhealthy
- **Event Analysis**: Distinguishes between critical events and warnings
- **Comprehensive Logging**: Detailed CloudWatch logs for troubleshooting

## How It Works

The Lambda function performs the following checks:

1. **EC2 AZ Status**: Verifies the AZ exists and is in "available" state
2. **Health Events**: Queries AWS Health API for recent events (last 7 days)
3. **Event Classification**: Categorizes events by severity
4. **Health Analysis**: Aggregates findings to determine overall AZ health

## Health Status Levels

- **healthy**: AZ is operating normally with no issues
- **degraded**: AZ has warnings or non-critical events
- **unhealthy**: AZ has critical issues or is not available

## Prerequisites

### AWS Support Plan

AWS Health API requires either:
- AWS Business Support plan, or
- AWS Enterprise Support plan

Without these, the function will still check EC2 AZ status but won't retrieve Health API events.

### IAM Permissions

The Lambda execution role needs the following permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeAvailabilityZones"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "health:DescribeEvents",
        "health:DescribeEventDetails",
        "health:DescribeAffectedEntities"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
```

## Deployment

### Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with credentials
- AWS account with appropriate permissions

### Option 1: Automated Deployment (Recommended)

Use the provided deployment script:

```bash
# Run the deployment script
./deploy.sh

# Or with custom configuration
FUNCTION_NAME=my-az-check AWS_REGION=eu-west-1 ./deploy.sh
```

The script will:
1. Initialize Terraform
2. Create/update terraform.tfvars
3. Validate the configuration
4. Show a plan of changes
5. Apply after confirmation

### Option 2: Manual Terraform Deployment

```bash
# Navigate to Terraform directory
cd terraform

# Initialize Terraform
terraform init

# (Optional) Create terraform.tfvars from example
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

### Option 3: AWS Console

1. Create a new Lambda function in the AWS Console
2. Upload the code:
   ```bash
   zip -r function.zip lambda_function.py
   ```
3. Upload `function.zip` to Lambda
4. Set runtime to Python 3.11 or later
5. Configure IAM role with required permissions
6. Set timeout to at least 30 seconds

## Terraform Configuration

The Terraform configuration includes:

- **Lambda Function**: Python 3.11 runtime with configurable timeout and memory
- **IAM Role**: Execution role with required permissions for EC2 and Health API
- **CloudWatch Logs**: Log group with configurable retention period
- **Outputs**: Function ARN, role ARN, and invoke commands

### Customizable Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `function_name` | Name of the Lambda function | `az-health-check` |
| `aws_region` | AWS region for deployment | `us-east-1` |
| `lambda_timeout` | Function timeout in seconds | `30` |
| `lambda_memory_size` | Memory allocation in MB | `256` |
| `log_retention_days` | CloudWatch Logs retention | `7` |
| `tags` | Resource tags | See terraform.tfvars.example |

### Terraform State Management

For production use, configure remote state:

```hcl
# Add to terraform/versions.tf
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "az-health-check/terraform.tfstate"
    region = "us-east-1"
  }
}
```

## Usage

### Input Event Format

```json
{
  "availability_zone": "us-east-1a",
  "region": "us-east-1"
}
```

**Parameters:**
- `availability_zone` (required): AZ name (e.g., "us-east-1a", "eu-west-1b")
- `region` (optional): AWS region; if omitted, inferred from AZ name

### Response Format

#### Healthy AZ Example

```json
{
  "availability_zone": "us-east-1a",
  "region": "us-east-1",
  "timestamp": "2025-10-23T15:30:00.123456",
  "health": {
    "status": "healthy",
    "severity": "healthy",
    "message": "AZ is healthy",
    "issues": [],
    "critical_events": [],
    "warning_events": [],
    "az_info": {
      "exists": true,
      "zone_name": "us-east-1a",
      "zone_id": "use1-az1",
      "state": "available",
      "region": "us-east-1",
      "messages": [],
      "network_border_group": "us-east-1"
    }
  }
}
```

#### Unhealthy AZ Example

```json
{
  "availability_zone": "us-east-1a",
  "region": "us-east-1",
  "timestamp": "2025-10-23T15:30:00.123456",
  "health": {
    "status": "unhealthy",
    "severity": "critical",
    "message": "AZ is unhealthy",
    "issues": [
      "Critical event: AWS_EC2_INSTANCE_STORE_DRIVE_PERFORMANCE_DEGRADED - EC2"
    ],
    "critical_events": [
      {
        "arn": "arn:aws:health:us-east-1::event/EC2/AWS_EC2_INSTANCE_STORE_DRIVE_PERFORMANCE_DEGRADED/...",
        "service": "EC2",
        "event_type_code": "AWS_EC2_INSTANCE_STORE_DRIVE_PERFORMANCE_DEGRADED",
        "event_type_category": "issue",
        "status": "open",
        "start_time": "2025-10-23T14:00:00",
        "end_time": null,
        "last_updated": "2025-10-23T15:00:00"
      }
    ],
    "warning_events": [],
    "az_info": {
      "exists": true,
      "zone_name": "us-east-1a",
      "zone_id": "use1-az1",
      "state": "available",
      "region": "us-east-1",
      "messages": [],
      "network_border_group": "us-east-1"
    }
  }
}
```

### Invoking the Function

#### AWS CLI

```bash
aws lambda invoke \
  --function-name az-health-check \
  --payload '{"availability_zone":"us-east-1a"}' \
  response.json

cat response.json
```

#### Python (boto3)

```python
import boto3
import json

lambda_client = boto3.client('lambda')

response = lambda_client.invoke(
    FunctionName='az-health-check',
    InvocationType='RequestResponse',
    Payload=json.dumps({
        'availability_zone': 'us-east-1a'
    })
)

result = json.loads(response['Payload'].read())
print(json.dumps(result, indent=2))
```

#### EventBridge Rule (Scheduled Check)

Create an EventBridge rule to check AZ health periodically:

```bash
# Create rule to run every 5 minutes
aws events put-rule \
  --name az-health-check-schedule \
  --schedule-expression "rate(5 minutes)"

# Add Lambda as target
aws events put-targets \
  --rule az-health-check-schedule \
  --targets "Id"="1","Arn"="arn:aws:lambda:REGION:ACCOUNT:function:az-health-check","Input"='{"availability_zone":"us-east-1a"}'

# Grant EventBridge permission to invoke Lambda
aws lambda add-permission \
  --function-name az-health-check \
  --statement-id AllowEventBridgeInvoke \
  --action lambda:InvokeFunction \
  --principal events.amazonaws.com \
  --source-arn arn:aws:events:REGION:ACCOUNT:rule/az-health-check-schedule
```

## Testing Locally

```bash
# Install dependencies
pip install -r requirements.txt

# Run the test
python lambda_function.py
```

## Monitoring

The function logs to CloudWatch Logs. Key log messages include:

- AZ health check initiation
- Number of health events found
- Health status determination
- Any errors encountered

### CloudWatch Metrics

Consider creating custom metrics based on the function's output:

```python
import boto3

cloudwatch = boto3.client('cloudwatch')

# Publish custom metric
cloudwatch.put_metric_data(
    Namespace='AZHealth',
    MetricData=[
        {
            'MetricName': 'AZHealthStatus',
            'Value': 1 if status == 'healthy' else 0,
            'Unit': 'None',
            'Dimensions': [
                {'Name': 'AvailabilityZone', 'Value': 'us-east-1a'}
            ]
        }
    ]
)
```

## Use Cases

1. **Automated Monitoring**: Schedule regular health checks via EventBridge
2. **Pre-Deployment Validation**: Check AZ health before deploying resources
3. **Incident Response**: Quick AZ health assessment during outages
4. **Multi-AZ Validation**: Check all AZs in a region for balanced deployments
5. **Integration with Alerting**: Trigger alerts when AZ issues are detected

## Limitations

- AWS Health API is only available in `us-east-1` region
- Health API requires Business or Enterprise Support plan
- Health events are limited to the last 7 days
- Some AZ issues may not be reflected in Health API immediately

## Troubleshooting

### "SubscriptionRequiredException" Error

This means you don't have AWS Business or Enterprise Support. The function will still work but won't fetch Health API events.

### Permission Denied Errors

Ensure the Lambda execution role has the required IAM permissions listed above.

### Timeout Errors

Increase the Lambda timeout setting (recommended: 30-60 seconds).

## Contributing

Contributions welcome! Please ensure code follows best practices for security and error handling.

## License

See LICENSE file for details.
