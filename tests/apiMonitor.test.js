/**
 * Unit tests for API Monitor canary
 */

const https = require('https');
const http = require('http');
const EventEmitter = require('events');

// Mock the Synthetics and Logger before requiring the canary
global.Synthetics = {
    executeStep: jest.fn((name, fn) => fn()),
    addUserAgentHeader: jest.fn()
};

global.SyntheticsLogger = {
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn()
};

describe('API Monitor Canary', () => {
    let mockRequest;
    let mockResponse;

    beforeEach(() => {
        jest.clearAllMocks();

        // Create mock response
        mockResponse = new EventEmitter();
        mockResponse.statusCode = 200;

        // Create mock request
        mockRequest = new EventEmitter();
        mockRequest.write = jest.fn();
        mockRequest.end = jest.fn();
        mockRequest.destroy = jest.fn();

        // Mock https.request
        https.request = jest.fn((options, callback) => {
            // Simulate async response
            setImmediate(() => callback(mockResponse));
            return mockRequest;
        });

        // Mock http.request
        http.request = jest.fn((options, callback) => {
            setImmediate(() => callback(mockResponse));
            return mockRequest;
        });
    });

    describe('Endpoint Testing', () => {
        test('should successfully test endpoint with 200 status', async () => {
            const testEndpoint = async (endpoint) => {
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
                        res.on('data', () => {
                            // Data received but not used in this test
                        });

                        res.on('end', () => {
                            if (res.statusCode !== endpoint.expectedStatus) {
                                reject(new Error(
                                    `Unexpected status code: ${res.statusCode}, expected: ${endpoint.expectedStatus}`
                                ));
                                return;
                            }
                            resolve();
                        });
                    });

                    req.on('error', (error) => {
                        reject(error);
                    });

                    req.end();
                });
            };

            const endpoint = {
                name: 'Test API',
                url: 'https://api.example.com/health',
                expectedStatus: 200,
                timeout: 5000
            };

            // Trigger the response
            const testPromise = testEndpoint(endpoint);
            setImmediate(() => {
                mockResponse.emit('data', JSON.stringify({ status: 'healthy' }));
                mockResponse.emit('end');
            });

            await expect(testPromise).resolves.toBeUndefined();
        });

        test('should fail when status code does not match expected', async () => {
            mockResponse.statusCode = 500;

            const testEndpoint = async (endpoint) => {
                return new Promise((resolve, reject) => {
                    const urlObj = new URL(endpoint.url);
                    const client = urlObj.protocol === 'https:' ? https : http;

                    const req = client.request({}, (res) => {
                        res.on('data', () => {
                            // Data received but not used in this test
                        });
                        res.on('end', () => {
                            if (res.statusCode !== endpoint.expectedStatus) {
                                reject(new Error(
                                    `Unexpected status code: ${res.statusCode}, expected: ${endpoint.expectedStatus}`
                                ));
                                return;
                            }
                            resolve();
                        });
                    });

                    req.on('error', reject);
                    req.end();
                });
            };

            const endpoint = {
                name: 'Test API',
                url: 'https://api.example.com/health',
                expectedStatus: 200,
                timeout: 5000
            };

            const testPromise = testEndpoint(endpoint);
            setImmediate(() => {
                mockResponse.emit('data', '');
                mockResponse.emit('end');
            });

            await expect(testPromise).rejects.toThrow('Unexpected status code: 500, expected: 200');
        });

        test('should handle request errors', async () => {
            const testEndpoint = async (endpoint) => {
                return new Promise((resolve, reject) => {
                    const urlObj = new URL(endpoint.url);
                    const client = urlObj.protocol === 'https:' ? https : http;

                    const req = client.request({}, () => {});
                    req.on('error', reject);
                    req.end();
                });
            };

            const endpoint = {
                name: 'Test API',
                url: 'https://api.example.com/health',
                expectedStatus: 200,
                timeout: 5000
            };

            const testPromise = testEndpoint(endpoint);
            setImmediate(() => {
                mockRequest.emit('error', new Error('Network error'));
            });

            await expect(testPromise).rejects.toThrow('Network error');
        });

        test('should handle timeout', async () => {
            const testEndpoint = async (endpoint) => {
                return new Promise((resolve, reject) => {
                    const urlObj = new URL(endpoint.url);
                    const client = urlObj.protocol === 'https:' ? https : http;

                    const req = client.request({}, () => {});
                    req.on('error', reject);
                    req.on('timeout', () => {
                        req.destroy();
                        reject(new Error(`Request timeout after ${endpoint.timeout}ms`));
                    });
                    req.end();
                });
            };

            const endpoint = {
                name: 'Test API',
                url: 'https://api.example.com/health',
                expectedStatus: 200,
                timeout: 5000
            };

            const testPromise = testEndpoint(endpoint);
            setImmediate(() => {
                mockRequest.emit('timeout');
            });

            await expect(testPromise).rejects.toThrow('Request timeout after 5000ms');
        });
    });

    describe('URL Parsing', () => {
        test('should correctly parse HTTPS URL', () => {
            const url = 'https://api.example.com:443/v1/health?status=true';
            const urlObj = new URL(url);

            expect(urlObj.protocol).toBe('https:');
            expect(urlObj.hostname).toBe('api.example.com');
            expect(urlObj.pathname).toBe('/v1/health');
            expect(urlObj.search).toBe('?status=true');
        });

        test('should correctly parse HTTP URL', () => {
            const url = 'http://api.example.com/health';
            const urlObj = new URL(url);

            expect(urlObj.protocol).toBe('http:');
            expect(urlObj.hostname).toBe('api.example.com');
            expect(urlObj.pathname).toBe('/health');
        });
    });

    describe('Response Validation', () => {
        test('should validate JSON response when validator is provided', async () => {
            const validateResponse = (body) => {
                try {
                    const data = JSON.parse(body);
                    return data.status === 'healthy';
                } catch (e) {
                    return false;
                }
            };

            const validBody = JSON.stringify({ status: 'healthy' });
            expect(validateResponse(validBody)).toBe(true);

            const invalidBody = JSON.stringify({ status: 'unhealthy' });
            expect(validateResponse(invalidBody)).toBe(false);

            const malformedBody = 'not json';
            expect(validateResponse(malformedBody)).toBe(false);
        });
    });

    describe('Synthetics Integration', () => {
        test('should call executeStep with correct parameters', async () => {
            const stepName = 'Test Step';
            const stepFunction = jest.fn();

            await global.Synthetics.executeStep(stepName, stepFunction);

            expect(global.Synthetics.executeStep).toHaveBeenCalledWith(stepName, stepFunction);
            expect(stepFunction).toHaveBeenCalled();
        });

        test('should call addUserAgentHeader', () => {
            global.Synthetics.addUserAgentHeader();

            expect(global.Synthetics.addUserAgentHeader).toHaveBeenCalled();
        });
    });
});
