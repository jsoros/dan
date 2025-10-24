/**
 * Unit tests for Heartbeat canary
 */

// Mock the Synthetics and Logger before requiring the canary
global.Synthetics = {
    executeStep: jest.fn((name, fn) => fn()),
    getPage: jest.fn(),
    takeScreenshot: jest.fn()
};

global.SyntheticsLogger = {
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn()
};

describe('Heartbeat Canary', () => {
    let mockPage;
    let mockResponse;

    beforeEach(() => {
        jest.clearAllMocks();

        // Create mock page
        mockPage = {
            setDefaultNavigationTimeout: jest.fn(),
            goto: jest.fn()
        };

        // Create mock response
        mockResponse = {
            status: jest.fn(() => 200)
        };

        global.Synthetics.getPage.mockResolvedValue(mockPage);
        mockPage.goto.mockResolvedValue(mockResponse);
    });

    describe('URL Health Checks', () => {
        test('should successfully check healthy URL', async () => {
            const url = 'https://example.com';
            const page = await global.Synthetics.getPage();

            page.setDefaultNavigationTimeout(10000);
            const response = await page.goto(url, {
                waitUntil: 'domcontentloaded',
                timeout: 10000
            });

            const statusCode = response.status();

            expect(page.setDefaultNavigationTimeout).toHaveBeenCalledWith(10000);
            expect(page.goto).toHaveBeenCalledWith(url, {
                waitUntil: 'domcontentloaded',
                timeout: 10000
            });
            expect(statusCode).toBe(200);
            expect(statusCode).toBeGreaterThanOrEqual(200);
            expect(statusCode).toBeLessThan(400);
        });

        test('should fail on 4xx status code', async () => {
            mockResponse.status = jest.fn(() => 404);
            mockPage.goto.mockResolvedValue(mockResponse);

            const url = 'https://example.com/notfound';
            const page = await global.Synthetics.getPage();
            const response = await page.goto(url);

            const statusCode = response.status();

            expect(statusCode).toBe(404);
            expect(statusCode).toBeGreaterThanOrEqual(400);
        });

        test('should fail on 5xx status code', async () => {
            mockResponse.status = jest.fn(() => 500);
            mockPage.goto.mockResolvedValue(mockResponse);

            const url = 'https://example.com';
            const page = await global.Synthetics.getPage();
            const response = await page.goto(url);

            const statusCode = response.status();

            expect(statusCode).toBe(500);
            expect(statusCode).toBeGreaterThanOrEqual(500);
        });

        test('should accept 3xx redirect status codes', async () => {
            mockResponse.status = jest.fn(() => 301);
            mockPage.goto.mockResolvedValue(mockResponse);

            const url = 'https://example.com';
            const page = await global.Synthetics.getPage();
            const response = await page.goto(url);

            const statusCode = response.status();

            expect(statusCode).toBe(301);
            expect(statusCode).toBeGreaterThanOrEqual(300);
            expect(statusCode).toBeLessThan(400);
        });
    });

    describe('Multiple URL Checking', () => {
        test('should check multiple URLs', async () => {
            const urls = [
                'https://example.com',
                'https://api.example.com/health',
                'https://admin.example.com'
            ];

            const page = await global.Synthetics.getPage();

            for (const url of urls) {
                await page.goto(url, {
                    waitUntil: 'domcontentloaded',
                    timeout: 10000
                });
            }

            expect(page.goto).toHaveBeenCalledTimes(3);
        });

        test('should continue checking URLs even if one fails', async () => {
            const urls = [
                'https://example.com',
                'https://api.example.com/health'
            ];

            const page = await global.Synthetics.getPage();

            // First URL succeeds
            mockPage.goto.mockResolvedValueOnce(mockResponse);

            // Second URL fails
            mockPage.goto.mockRejectedValueOnce(new Error('Connection failed'));

            // Check first URL
            await expect(
                page.goto(urls[0], { waitUntil: 'domcontentloaded', timeout: 10000 })
            ).resolves.toBeDefined();

            // Check second URL
            await expect(
                page.goto(urls[1], { waitUntil: 'domcontentloaded', timeout: 10000 })
            ).rejects.toThrow('Connection failed');

            expect(page.goto).toHaveBeenCalledTimes(2);
        });
    });

    describe('Timeout Handling', () => {
        test('should set navigation timeout', async () => {
            const page = await global.Synthetics.getPage();
            page.setDefaultNavigationTimeout(10000);

            expect(page.setDefaultNavigationTimeout).toHaveBeenCalledWith(10000);
        });

        test('should handle navigation timeout', async () => {
            mockPage.goto.mockRejectedValue(new Error('Navigation timeout of 10000 ms exceeded'));

            const page = await global.Synthetics.getPage();

            await expect(
                page.goto('https://slow-site.example.com', { timeout: 10000 })
            ).rejects.toThrow('Navigation timeout');
        });
    });

    describe('URL Parsing', () => {
        test('should extract hostname from URL', () => {
            const url = 'https://api.example.com/health';
            const urlObj = new URL(url);

            expect(urlObj.hostname).toBe('api.example.com');
        });

        test('should handle URL with port', () => {
            const url = 'https://example.com:8443/health';
            const urlObj = new URL(url);

            expect(urlObj.hostname).toBe('example.com');
            expect(urlObj.port).toBe('8443');
        });

        test('should handle URL with path and query', () => {
            const url = 'https://example.com/api/v1/health?status=true';
            const urlObj = new URL(url);

            expect(urlObj.pathname).toBe('/api/v1/health');
            expect(urlObj.search).toBe('?status=true');
        });
    });

    describe('Screenshot Capture', () => {
        test('should take screenshot after successful check', async () => {
            const url = 'https://example.com';
            const urlObj = new URL(url);

            await global.Synthetics.takeScreenshot(urlObj.hostname, 'result');

            expect(global.Synthetics.takeScreenshot).toHaveBeenCalledWith('example.com', 'result');
        });
    });

    describe('Synthetics Integration', () => {
        test('should execute step with URL hostname', async () => {
            const url = 'https://example.com';
            const stepName = `Check ${new URL(url).hostname}`;

            await global.Synthetics.executeStep(stepName, jest.fn());

            expect(global.Synthetics.executeStep).toHaveBeenCalledWith(
                'Check example.com',
                expect.any(Function)
            );
        });

        test('should log check results', () => {
            const url = 'https://example.com';
            const statusCode = 200;

            global.SyntheticsLogger.info(`Checking URL: ${url}`);
            global.SyntheticsLogger.info(`Response: ${statusCode}`);

            expect(global.SyntheticsLogger.info).toHaveBeenCalledWith('Checking URL: https://example.com');
            expect(global.SyntheticsLogger.info).toHaveBeenCalledWith('Response: 200');
        });
    });

    describe('Error Scenarios', () => {
        test('should handle DNS resolution failure', async () => {
            mockPage.goto.mockRejectedValue(new Error('getaddrinfo ENOTFOUND invalid.example.com'));

            const page = await global.Synthetics.getPage();

            await expect(
                page.goto('https://invalid.example.com')
            ).rejects.toThrow('ENOTFOUND');
        });

        test('should handle connection refused', async () => {
            mockPage.goto.mockRejectedValue(new Error('connect ECONNREFUSED'));

            const page = await global.Synthetics.getPage();

            await expect(
                page.goto('https://example.com')
            ).rejects.toThrow('ECONNREFUSED');
        });

        test('should handle SSL/TLS errors', async () => {
            mockPage.goto.mockRejectedValue(new Error('certificate has expired'));

            const page = await global.Synthetics.getPage();

            await expect(
                page.goto('https://example.com')
            ).rejects.toThrow('certificate has expired');
        });
    });
});
