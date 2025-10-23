# Deployment Guide

This guide walks you through deploying AWS Synthetic canaries step by step.

## Prerequisites Checklist

- [ ] AWS account with admin access (or appropriate IAM permissions)
- [ ] AWS CLI installed and configured
- [ ] Terraform installed (version >= 1.0)
- [ ] Email address for receiving alerts

## Step-by-Step Deployment

### Step 1: Verify AWS Credentials

```bash
# Check AWS CLI is configured
aws sts get-caller-identity

# Expected output shows your AWS account ID and user ARN
```

### Step 2: Customize Configuration

1. Copy the example variables file:
```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

2. Edit `terraform/terraform.tfvars` with your editor:
```bash
# Using nano
nano terraform/terraform.tfvars

# Or using vim
vim terraform/terraform.tfvars
```

3. Set the following required variables:
```hcl
aws_region  = "us-east-1"        # Your preferred AWS region
environment = "dev"              # Environment name
alert_email = "you@example.com"  # Your email for alerts
```

### Step 3: Customize Canary Scripts

#### API Monitor

Edit `canaries/api-monitor/apiMonitor.js` and update the endpoints array:

```javascript
const endpoints = [
    {
        name: 'Production API Health',
        url: 'https://api.yourcompany.com/health',
        expectedStatus: 200,
        timeout: 5000
    },
    {
        name: 'Production API Users',
        url: 'https://api.yourcompany.com/v1/users',
        expectedStatus: 200,
        timeout: 5000,
        headers: {
            'Content-Type': 'application/json',
            // Add auth if needed:
            // 'Authorization': 'Bearer YOUR_TOKEN'
        }
    }
];
```

**Important**: Replace `example.com` URLs with your actual endpoints!

#### UI Monitor

Edit `canaries/ui-monitor/uiMonitor.js` and update the config:

```javascript
const config = {
    url: 'https://www.yourcompany.com',
    viewportWidth: 1920,
    viewportHeight: 1080,
    timeout: 30000
};
```

Also customize the UI element selectors based on your website structure:

```javascript
// Update these selectors to match your website
const logo = await page.$('img[alt*="Your Company"], .your-logo-class');
const nav = await page.$('nav, .your-nav-class');
```

#### Heartbeat

Edit `canaries/heartbeat/heartbeat.js` and update the URLs:

```javascript
const urls = [
    'https://www.yourcompany.com',
    'https://api.yourcompany.com/health',
    'https://admin.yourcompany.com'
];
```

### Step 4: Review Terraform Plan

Initialize Terraform:
```bash
make init
# Or: cd terraform && terraform init
```

Review the planned changes:
```bash
make plan
# Or: cd terraform && terraform plan
```

Expected output should show:
- 1 S3 bucket
- 3 canaries (api-monitor, ui-monitor, heartbeat)
- 1 IAM role and policies
- 1 SNS topic
- 4 CloudWatch alarms
- Various supporting resources

### Step 5: Deploy

Apply the Terraform configuration:
```bash
make apply
# Or: cd terraform && terraform apply
```

When prompted, type `yes` to confirm.

Deployment typically takes 2-3 minutes.

### Step 6: Confirm SNS Subscription

1. Check your email inbox for a message from AWS Notifications
2. Subject: "AWS Notification - Subscription Confirmation"
3. Click the "Confirm subscription" link
4. You should see a confirmation page

**Important**: You won't receive alerts until you confirm the subscription!

### Step 7: Verify Deployment

#### Check Canaries in AWS Console

1. Open the CloudWatch Synthetics console:
```bash
# Get the dashboard URL
cd terraform
terraform output cloudwatch_dashboard_url
```

2. You should see three canaries:
   - synthetics-api-monitor-dev
   - synthetics-ui-monitor-dev
   - synthetics-heartbeat-dev

3. Initial status will be "Starting" or "Running"

#### Monitor First Runs

Wait 5-15 minutes for the first canary runs to complete, then:

1. Click on each canary name
2. Check the "Availability" tab - should show success/failure
3. Check the "Screenshots" tab (UI monitor) - should show captured images
4. Check the "Logs" tab - should show execution logs

### Step 8: Review CloudWatch Alarms

1. Navigate to CloudWatch > Alarms
2. You should see 4 alarms:
   - synthetics-api-monitor-failed-dev
   - synthetics-api-monitor-slow-dev
   - synthetics-ui-monitor-failed-dev
   - synthetics-heartbeat-failed-dev

3. Initial state will be "Insufficient data" - this is normal
4. After a few runs, state should change to "OK"

## Troubleshooting

### Issue: Canaries Fail Immediately

**Symptoms**: Canaries show "Failed" status right after deployment

**Common Causes**:
1. URLs are unreachable (still using example.com)
2. Timeout too short for slow endpoints
3. Expected status code doesn't match actual response

**Solutions**:
```bash
# Check canary logs
aws logs tail /aws/lambda/cwsyn-synthetics-api-monitor-dev --follow

# Update canary script
vim canaries/api-monitor/apiMonitor.js

# Redeploy
make apply
```

### Issue: No Email Alerts

**Symptoms**: Canary fails but no email received

**Solutions**:
1. Check SNS subscription status:
```bash
aws sns list-subscriptions-by-topic \
  --topic-arn $(cd terraform && terraform output -raw sns_topic_arn)
```

2. Status should be "Confirmed", not "PendingConfirmation"
3. If pending, check spam folder for confirmation email
4. Manually trigger alarm to test:
```bash
aws cloudwatch set-alarm-state \
  --alarm-name synthetics-api-monitor-failed-dev \
  --state-value ALARM \
  --state-reason "Testing alert"
```

### Issue: High Costs

**Symptoms**: AWS bill higher than expected

**Solutions**:
1. Reduce canary frequency:
```hcl
# In terraform.tfvars
api_monitor_schedule = "rate(15 minutes)"  # Instead of 5 minutes
```

2. Stop canaries temporarily:
```hcl
# In terraform.tfvars
start_canary = false
```

3. Redeploy:
```bash
make apply
```

### Issue: Permission Denied Errors

**Symptoms**: Terraform fails with permission errors

**Solutions**:
1. Verify AWS credentials:
```bash
aws sts get-caller-identity
```

2. Ensure IAM user/role has permissions for:
   - CloudWatch Synthetics
   - S3
   - IAM
   - SNS
   - CloudWatch Logs

3. Consider using AWS managed policy: `PowerUserAccess` (for testing)

## Post-Deployment Tasks

### 1. Fine-Tune Alarm Thresholds

After monitoring for a few days, adjust thresholds based on actual behavior:

```hcl
# In terraform.tfvars
alarm_threshold = 95          # Increase if too many false alarms
duration_threshold_ms = 15000 # Increase if API is normally slow
```

### 2. Set Up Additional Monitoring

Consider adding:
- CloudWatch Dashboard for visualization
- Additional canaries for critical endpoints
- Integration with incident management (PagerDuty, Opsgenie)

### 3. Configure Retention

Adjust retention based on compliance requirements:

```hcl
# In terraform.tfvars
artifact_retention_days = 90   # For compliance
failure_retention_days = 90    # Keep failures longer
success_retention_days = 7     # Save storage costs
```

### 4. Enable Cost Monitoring

Track canary costs:

```bash
# Enable cost allocation tags
aws ce create-cost-category-definition \
  --name "Synthetics" \
  --rules file://cost-category-rules.json
```

## Production Deployment

When moving to production:

1. Create separate environment:
```hcl
# In terraform.tfvars
environment = "prod"
```

2. Use stricter alerting:
```hcl
alarm_threshold = 99
alarm_evaluation_periods = 1
```

3. Consider using Terraform workspaces:
```bash
terraform workspace new prod
terraform workspace select prod
```

4. Set up monitoring on actual production endpoints

5. Configure on-call rotation for alerts

6. Document runbooks for common failures

## Cleanup

To remove all resources:

```bash
make destroy
# Or: cd terraform && terraform destroy
```

Type `yes` when prompted.

**Warning**: This deletes all canaries, alarms, and artifacts permanently!

## Next Steps

- [ ] Review canary results daily for first week
- [ ] Adjust alarm thresholds based on baseline
- [ ] Add authentication to API canaries if needed
- [ ] Set up integration with incident management
- [ ] Document escalation procedures
- [ ] Schedule regular review of canary effectiveness

## Support

For issues or questions:
1. Check CloudWatch Logs for canary execution details
2. Review [AWS CloudWatch Synthetics documentation](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Synthetics_Canaries.html)
3. Open an issue in this repository
