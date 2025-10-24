const synthetics = require('Synthetics');
const log = require('SyntheticsLogger');
const https = require('https');
const http = require('http');

/**
 * API Monitoring Canary
 *
 * This canary monitors REST API endpoints for availability and response times.
 * It validates HTTP status codes, response times, and optionally validates response content.
 */

const apiCanaryBlueprint = async function () {
    // Configuration - customize these endpoints for your needs
    const endpoints = [
        {
            name: 'API Health Check',
            url: 'https://api.example.com/health',
            expectedStatus: 200,
            timeout: 5000,
            validateResponse: (body) => {
                // Optional: validate response content
                try {
                    const data = JSON.parse(body);
                    return data.status === 'healthy';
                } catch (e) {
                    log.error('Failed to parse response:', e);
                    return false;
                }
            }
        },
        {
            name: 'API Users Endpoint',
            url: 'https://api.example.com/v1/users',
            expectedStatus: 200,
            timeout: 5000,
            headers: {
                'Content-Type': 'application/json'
                // Add authentication headers if needed
                // 'Authorization': 'Bearer YOUR_TOKEN'
            }
        },
        {
            name: 'API Products Endpoint',
            url: 'https://api.example.com/v1/products',
            expectedStatus: 200,
            timeout: 5000
        }
    ];

    // Test each endpoint
    for (const endpoint of endpoints) {
        await testEndpoint(endpoint);
    }
};

/**
 * Test a single API endpoint
 */
async function testEndpoint(endpoint) {
    const stepName = endpoint.name;

    await synthetics.executeStep(stepName, async function () {
        const startTime = Date.now();

        log.info(`Testing endpoint: ${endpoint.url}`);

        return new Promise((resolve, reject) => {
            const urlObj = new URL(endpoint.url);
            const client = urlObj.protocol === 'https:' ? https : http;

            const options = {
                hostname: urlObj.hostname,
                port: urlObj.port,
                path: urlObj.pathname + urlObj.search,
                method: endpoint.method || 'GET',
                headers: endpoint.headers || {},
                timeout: endpoint.timeout || 5000
            };

            const req = client.request(options, (res) => {
                let body = '';

                res.on('data', (chunk) => {
                    body += chunk;
                });

                res.on('end', () => {
                    const duration = Date.now() - startTime;
                    log.info(`Response received in ${duration}ms with status ${res.statusCode}`);

                    // Validate status code
                    if (res.statusCode !== endpoint.expectedStatus) {
                        reject(new Error(
                            `Unexpected status code: ${res.statusCode}, expected: ${endpoint.expectedStatus}`
                        ));
                        return;
                    }

                    // Validate response content if validator provided
                    if (endpoint.validateResponse) {
                        if (!endpoint.validateResponse(body)) {
                            reject(new Error('Response validation failed'));
                            return;
                        }
                    }

                    // Log custom metrics
                    synthetics.addUserAgentHeader();

                    log.info(`✓ ${stepName} passed - Response time: ${duration}ms`);
                    resolve();
                });
            });

            req.on('error', (error) => {
                log.error(`Request failed: ${error.message}`);
                reject(error);
            });

            req.on('timeout', () => {
                req.destroy();
                reject(new Error(`Request timeout after ${endpoint.timeout}ms`));
            });

            // Send POST/PUT data if provided
            if (endpoint.body) {
                req.write(JSON.stringify(endpoint.body));
            }

            req.end();
        });
    });
}

exports.handler = async () => {
    return await apiCanaryBlueprint();
};
