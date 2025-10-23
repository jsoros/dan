# AWS Synthetic Monitoring

This repository contains sample AWS CloudWatch Synthetics canaries for monitoring application availability and performance. The canaries use Puppeteer to test web applications and APIs, taking screenshots and collecting performance metrics.

## Overview

AWS CloudWatch Synthetics allows you to create canaries (configurable scripts) that run on a schedule to monitor your endpoints and APIs. This project includes:

- **API Monitor**: Tests REST API endpoints for availability and response times
- **UI Monitor**: Performs visual monitoring of web pages using Puppeteer
- **Heartbeat**: Simple health checks for basic uptime monitoring

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     AWS CloudWatch                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ API Monitor  │  │  UI Monitor  │  │  Heartbeat   │      │
│  │   Canary     │  │    Canary    │  │    Canary    │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                 │                 │               │
│         └─────────────────┴─────────────────┘               │
│                           │                                 │
│         ┌─────────────────┴─────────────────┐               │
│         │                                   │               │
│    ┌────▼─────┐                      ┌──────▼─────┐        │
│    │    S3    │                      │ CloudWatch │        │
│    │ Artifacts│                      │   Alarms   │        │
│    └──────────┘                      └──────┬─────┘        │
│                                             │               │
│                                      ┌──────▼─────┐        │
│                                      │    SNS     │        │
│                                      │   Alerts   │        │
│                                      └────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- AWS account with appropriate permissions
- AWS CLI configured with credentials

## Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd dan
```

### 2. Configure Variables

Copy the example variables file and customize it:

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

Edit `terraform/terraform.tfvars` and set your values:

```hcl
aws_region  = "us-east-1"
environment = "dev"
alert_email = "your-email@example.com"
```

### 3. Customize Canary Scripts

Before deploying, customize the canary scripts for your endpoints:

**API Monitor** (`canaries/api-monitor/apiMonitor.js`):
```javascript
const endpoints = [
    {
        name: 'Your API Health Check',
        url: 'https://your-api.example.com/health',
        expectedStatus: 200,
        timeout: 5000
    }
];
```

**UI Monitor** (`canaries/ui-monitor/uiMonitor.js`):
```javascript
const config = {
    url: 'https://your-website.example.com',
    viewportWidth: 1920,
    viewportHeight: 1080
};
```

**Heartbeat** (`canaries/heartbeat/heartbeat.js`):
```javascript
const urls = [
    'https://your-website.example.com',
    'https://your-api.example.com/health'
];
```

### 4. Deploy Infrastructure

Using Make:
```bash
make init
make plan
make apply
```

Or using Terraform directly:
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 5. Confirm SNS Subscription

After deployment, you'll receive an email to confirm your SNS subscription for alerts. Click the confirmation link in the email.

## Canary Details

### API Monitor

- **Purpose**: Monitor REST API endpoints
- **Schedule**: Every 5 minutes (configurable)
- **Timeout**: 60 seconds
- **Features**:
  - Validates HTTP status codes
  - Measures response times
  - Optional response content validation
  - Supports custom headers (e.g., authentication)

### UI Monitor

- **Purpose**: Visual monitoring of web applications
- **Schedule**: Every 15 minutes (configurable)
- **Timeout**: 120 seconds
- **Features**:
  - Takes screenshots of pages
  - Validates UI elements
  - Tests responsive design (desktop/mobile)
  - Collects performance metrics
  - Tests user interactions (e.g., search)

### Heartbeat

- **Purpose**: Simple uptime monitoring
- **Schedule**: Every 5 minutes (configurable)
- **Timeout**: 30 seconds
- **Features**:
  - Checks basic availability
  - Minimal resource usage
  - Fast execution

## CloudWatch Alarms

The deployment includes CloudWatch alarms for:

1. **Success Rate**: Triggers when success rate drops below threshold (default: 90%)
2. **Response Time**: Triggers when API response time exceeds threshold (default: 10 seconds)

All alarms send notifications to the configured SNS topic.

## Viewing Results

### CloudWatch Console

Access the Synthetics console:
```
https://console.aws.amazon.com/cloudwatch/home?region=<region>#synthetics:canary/list
```

Or get the URL from Terraform output:
```bash
cd terraform
terraform output cloudwatch_dashboard_url
```

### S3 Artifacts

Screenshots, logs, and HAR files are stored in the S3 bucket:
```bash
aws s3 ls s3://$(terraform output -raw canary_bucket_name)/
```

## Configuration

### Schedule Expressions

Canaries support two types of schedule expressions:

**Rate expressions**:
```hcl
rate(5 minutes)
rate(1 hour)
rate(1 day)
```

**Cron expressions**:
```hcl
cron(0 */5 * * ? *)   # Every 5 hours
cron(0 0 * * ? *)     # Daily at midnight
cron(0 12 * * MON-FRI *) # Weekdays at noon
```

### Retention Periods

- `artifact_retention_days`: Days to keep artifacts in S3 (default: 30)
- `success_retention_days`: Days to keep successful runs (default: 31)
- `failure_retention_days`: Days to keep failed runs (default: 31)

## Costs

CloudWatch Synthetics pricing (as of 2024):
- $0.0012 per canary run
- Example: 1 canary running every 5 minutes = ~8,640 runs/month = ~$10.37/month
- S3 storage costs for artifacts
- CloudWatch Logs storage costs

See [AWS Pricing](https://aws.amazon.com/cloudwatch/pricing/) for details.

## Troubleshooting

### Canary Fails to Start

1. Check IAM role permissions
2. Verify S3 bucket exists and is accessible
3. Check canary logs in CloudWatch Logs

### High Failure Rate

1. Review canary logs in CloudWatch
2. Check if monitored endpoints are accessible
3. Verify timeout settings are appropriate
4. Ensure network connectivity (VPC configuration if needed)

### No Alerts Received

1. Confirm SNS subscription in email
2. Check SNS topic subscription status
3. Verify alarm thresholds are correctly configured

## Development

### Adding New Canaries

1. Create canary script in `canaries/<name>/`
2. Add archive and S3 upload resources in `terraform/main.tf`
3. Add canary resource in `terraform/main.tf`
4. Add CloudWatch alarms in `terraform/cloudwatch_alarms.tf`
5. Update outputs in `terraform/outputs.tf`

### Testing Locally

Canaries use AWS Lambda runtime, so local testing is limited. However, you can:

1. Validate syntax:
```bash
node canaries/api-monitor/apiMonitor.js
```

2. Use AWS SAM for local Lambda testing (requires additional setup)

## Cleanup

To destroy all resources:

```bash
make destroy
```

Or:
```bash
cd terraform
terraform destroy
```

**Warning**: This will delete all canaries, alarms, and artifacts.

## Security Considerations

1. **Secrets Management**: Use AWS Secrets Manager or Parameter Store for API keys/tokens
2. **IAM Permissions**: Follow principle of least privilege
3. **S3 Bucket**: Public access is blocked by default
4. **Network Security**: Configure VPC if monitoring internal resources
5. **Sensitive Data**: Canaries may capture screenshots/logs - ensure compliance

## Best Practices

1. **Monitoring Frequency**: Balance between coverage and cost
2. **Timeout Values**: Set appropriate timeouts for each canary type
3. **Alert Thresholds**: Tune to reduce false positives
4. **Retention Periods**: Keep failure data longer for debugging
5. **Tagging**: Use consistent tags for cost allocation
6. **Documentation**: Keep canary scripts well-documented

## Resources

- [AWS CloudWatch Synthetics Documentation](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Synthetics_Canaries.html)
- [Synthetics Runtime Versions](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Synthetics_Canaries_Library.html)
- [Puppeteer Documentation](https://pptr.dev/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## License

See LICENSE file for details.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.
