# Canary Scripts

This directory contains the synthetic monitoring scripts (canaries) for AWS CloudWatch Synthetics.

## Directory Structure

```
canaries/
├── api-monitor/
│   └── apiMonitor.js      # REST API monitoring
├── ui-monitor/
│   └── uiMonitor.js       # Visual web monitoring
└── heartbeat/
    └── heartbeat.js       # Simple uptime checks
```

## Customization Guide

### API Monitor

The API monitor tests REST API endpoints for availability and performance.

**File**: `api-monitor/apiMonitor.js`

#### Basic Configuration

Update the `endpoints` array with your API endpoints:

```javascript
const endpoints = [
    {
        name: 'API Health Check',              // Descriptive name for CloudWatch
        url: 'https://api.example.com/health', // Your endpoint URL
        expectedStatus: 200,                    // Expected HTTP status code
        timeout: 5000                           // Timeout in milliseconds
    }
];
```

#### Adding Authentication

For APIs requiring authentication:

```javascript
{
    name: 'Authenticated API',
    url: 'https://api.example.com/v1/users',
    expectedStatus: 200,
    headers: {
        'Authorization': 'Bearer YOUR_TOKEN_HERE',
        'Content-Type': 'application/json'
    }
}
```

**Security Note**: Don't commit tokens to git! Use AWS Secrets Manager:

```javascript
const AWS = require('aws-sdk');
const secretsManager = new AWS.SecretsManager();

// At the start of your handler
const secret = await secretsManager.getSecretValue({
    SecretId: 'prod/api/token'
}).promise();

const token = JSON.parse(secret.SecretString).token;

const endpoints = [
    {
        name: 'Authenticated API',
        url: 'https://api.example.com/v1/users',
        expectedStatus: 200,
        headers: {
            'Authorization': `Bearer ${token}`
        }
    }
];
```

#### POST Requests

To test POST endpoints:

```javascript
{
    name: 'Create User API',
    url: 'https://api.example.com/v1/users',
    method: 'POST',
    expectedStatus: 201,
    headers: {
        'Content-Type': 'application/json'
    },
    body: {
        username: 'testuser',
        email: 'test@example.com'
    }
}
```

#### Response Validation

Validate response content:

```javascript
{
    name: 'API with Validation',
    url: 'https://api.example.com/health',
    expectedStatus: 200,
    validateResponse: (body) => {
        try {
            const data = JSON.parse(body);
            // Check required fields
            if (!data.status) return false;
            if (data.status !== 'healthy') return false;
            // Check database connection
            if (!data.database || data.database !== 'connected') return false;
            return true;
        } catch (e) {
            return false;
        }
    }
}
```

### UI Monitor

The UI monitor performs visual testing of web applications using Puppeteer.

**File**: `ui-monitor/uiMonitor.js`

#### Basic Configuration

Update the config object:

```javascript
const config = {
    url: 'https://www.yoursite.com',
    viewportWidth: 1920,
    viewportHeight: 1080,
    timeout: 30000  // 30 seconds
};
```

#### Custom Selectors

Update selectors to match your website's structure:

```javascript
// Logo check
const logo = await page.$('img[alt="Your Company Logo"]');
// Or by class
const logo = await page.$('.site-logo');

// Navigation
const nav = await page.$('nav.main-navigation');

// Main content
const main = await page.$('main#content');
```

#### Testing User Flows

Add custom user interactions:

```javascript
await synthetics.executeStep('UserLogin', async function () {
    // Navigate to login page
    await page.goto('https://www.yoursite.com/login');

    // Fill in form
    await page.type('#email', 'test@example.com');
    await page.type('#password', 'testpassword');

    // Click login button
    await page.click('button[type="submit"]');

    // Wait for redirect
    await page.waitForNavigation({ waitUntil: 'networkidle0' });

    // Verify login success
    const userMenu = await page.$('.user-menu');
    if (!userMenu) {
        throw new Error('Login failed - user menu not found');
    }

    // Take screenshot
    await synthetics.takeScreenshot('logged-in', 'result');
});
```

#### Testing Forms

```javascript
await synthetics.executeStep('TestContactForm', async function () {
    await page.goto('https://www.yoursite.com/contact');

    // Fill form fields
    await page.type('#name', 'Test User');
    await page.type('#email', 'test@example.com');
    await page.type('#message', 'This is a test message');

    // Submit
    await page.click('button[type="submit"]');

    // Wait for success message
    await page.waitForSelector('.success-message', { timeout: 5000 });

    await synthetics.takeScreenshot('form-submitted', 'result');
});
```

#### Checking for Broken Images

```javascript
await synthetics.executeStep('CheckBrokenImages', async function () {
    const images = await page.$$eval('img', imgs =>
        imgs.map(img => ({
            src: img.src,
            naturalWidth: img.naturalWidth
        }))
    );

    const brokenImages = images.filter(img => img.naturalWidth === 0);

    if (brokenImages.length > 0) {
        log.error(`Found ${brokenImages.length} broken images:`, brokenImages);
        throw new Error(`${brokenImages.length} images failed to load`);
    }

    log.info(`✓ All ${images.length} images loaded successfully`);
});
```

#### Performance Budgets

Set performance thresholds:

```javascript
await synthetics.executeStep('CheckPerformance', async function () {
    const performanceMetrics = JSON.parse(
        await page.evaluate(() => JSON.stringify(window.performance.timing))
    );

    const loadTime = performanceMetrics.loadEventEnd - performanceMetrics.navigationStart;
    const maxLoadTime = 3000; // 3 seconds

    log.info(`Page load time: ${loadTime}ms`);

    if (loadTime > maxLoadTime) {
        throw new Error(`Page load time ${loadTime}ms exceeds budget ${maxLoadTime}ms`);
    }
});
```

### Heartbeat

Simple availability monitoring.

**File**: `heartbeat/heartbeat.js`

#### Basic Configuration

Update the URLs array:

```javascript
const urls = [
    'https://www.example.com',
    'https://api.example.com/health',
    'https://admin.example.com',
    'https://blog.example.com'
];
```

#### Custom Success Criteria

Modify the `checkUrl` function for custom validation:

```javascript
async function checkUrl(url) {
    const stepName = `Check ${new URL(url).hostname}`;

    await synthetics.executeStep(stepName, async function () {
        const page = await synthetics.getPage();
        const response = await page.goto(url, {
            waitUntil: 'domcontentloaded',
            timeout: 10000
        });

        const statusCode = response.status();

        // Custom logic for different endpoints
        if (url.includes('/health')) {
            // Health endpoints should return 200
            if (statusCode !== 200) {
                throw new Error(`Health check failed: ${statusCode}`);
            }

            // Check response body
            const body = await response.text();
            if (!body.includes('healthy')) {
                throw new Error('Health status not healthy');
            }
        } else {
            // Regular pages accept 200-399
            if (statusCode < 200 || statusCode >= 400) {
                throw new Error(`Status ${statusCode} is not acceptable`);
            }
        }

        log.info(`✓ ${url} is healthy (${statusCode})`);
    });
}
```

## Advanced Patterns

### Environment-Specific Configuration

Use environment variables:

```javascript
const environment = process.env.ENVIRONMENT || 'dev';

const endpoints = {
    dev: ['https://dev-api.example.com'],
    staging: ['https://staging-api.example.com'],
    prod: ['https://api.example.com']
};

const urls = endpoints[environment];
```

### Retry Logic

Add retry for flaky endpoints:

```javascript
async function testEndpointWithRetry(endpoint, maxRetries = 3) {
    for (let i = 0; i < maxRetries; i++) {
        try {
            await testEndpoint(endpoint);
            return; // Success
        } catch (error) {
            if (i === maxRetries - 1) {
                throw error; // Last retry failed
            }
            log.warn(`Attempt ${i + 1} failed, retrying...`);
            await new Promise(resolve => setTimeout(resolve, 1000));
        }
    }
}
```

### Custom Metrics

Publish custom CloudWatch metrics:

```javascript
const AWS = require('aws-sdk');
const cloudwatch = new AWS.CloudWatch();

async function publishMetric(name, value) {
    await cloudwatch.putMetricData({
        Namespace: 'CustomSynthetics',
        MetricData: [{
            MetricName: name,
            Value: value,
            Unit: 'Milliseconds',
            Timestamp: new Date()
        }]
    }).promise();
}

// Usage
const startTime = Date.now();
// ... perform request ...
const duration = Date.now() - startTime;
await publishMetric('APIResponseTime', duration);
```

## Testing Locally

While full local testing isn't possible, you can validate syntax:

```bash
# Check for syntax errors
node -c canaries/api-monitor/apiMonitor.js
node -c canaries/ui-monitor/uiMonitor.js
node -c canaries/heartbeat/heartbeat.js
```

For more thorough local testing, use AWS SAM:

```bash
sam local invoke -t template.yaml
```

## Best Practices

1. **Keep Scripts Simple**: Each canary should test one primary thing
2. **Use Descriptive Names**: Make failures easy to identify
3. **Add Logging**: Use `log.info()` to track execution
4. **Set Reasonable Timeouts**: Too short = false alarms, too long = slow alerts
5. **Take Screenshots**: Visual evidence helps debugging
6. **Validate Thoroughly**: Check status codes AND response content
7. **Handle Errors Gracefully**: Provide clear error messages
8. **Version Control**: Commit all changes to track history
9. **Test After Changes**: Always verify changes work before deploying

## Troubleshooting

### Canary Times Out

Increase timeout in Terraform:

```hcl
# In terraform/main.tf
run_config {
  timeout_in_seconds = 120  # Increase from 60
}
```

### Module Not Found Errors

The Synthetics runtime includes these modules by default:
- `Synthetics`
- `SyntheticsLogger`
- `aws-sdk`

Don't try to use `require('puppeteer')` - use the provided Synthetics library instead.

### Screenshots Not Captured

Ensure you're using:
```javascript
await synthetics.takeScreenshot('name', 'result');
```

Not:
```javascript
await page.screenshot(); // This won't work
```

## Resources

- [Synthetics Node.js Library](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Synthetics_Canaries_Library_Nodejs.html)
- [Puppeteer API](https://pptr.dev/)
- [CloudWatch Synthetics Best Practices](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Synthetics_Canaries_WritingCanary.html)
