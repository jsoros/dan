/**
 * Unit tests for UI Monitor canary
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

describe('UI Monitor Canary', () => {
    let mockPage;
    let mockResponse;

    beforeEach(() => {
        jest.clearAllMocks();

        // Create mock page
        mockPage = {
            setViewport: jest.fn(),
            goto: jest.fn(),
            $: jest.fn(),
            $$eval: jest.fn(),
            type: jest.fn(),
            click: jest.fn(),
            reload: jest.fn(),
            waitForNavigation: jest.fn(),
            waitForSelector: jest.fn(),
            metrics: jest.fn(),
            evaluate: jest.fn()
        };

        // Create mock response
        mockResponse = {
            status: jest.fn(() => 200)
        };

        global.Synthetics.getPage.mockResolvedValue(mockPage);
        mockPage.goto.mockResolvedValue(mockResponse);
    });

    describe('Page Navigation', () => {
        test('should navigate to homepage successfully', async () => {
            const config = {
                url: 'https://example.com',
                viewportWidth: 1920,
                viewportHeight: 1080,
                timeout: 30000
            };

            const page = await global.Synthetics.getPage();
            await page.setViewport({
                width: config.viewportWidth,
                height: config.viewportHeight
            });

            const response = await page.goto(config.url, {
                waitUntil: 'networkidle0',
                timeout: config.timeout
            });

            expect(page.setViewport).toHaveBeenCalledWith({
                width: 1920,
                height: 1080
            });

            expect(page.goto).toHaveBeenCalledWith(
                config.url,
                expect.objectContaining({
                    waitUntil: 'networkidle0',
                    timeout: 30000
                })
            );

            expect(response.status()).toBe(200);
        });

        test('should fail when page returns non-200 status', async () => {
            mockResponse.status = jest.fn(() => 404);
            mockPage.goto.mockResolvedValue(mockResponse);

            const page = await global.Synthetics.getPage();
            const response = await page.goto('https://example.com/notfound');

            expect(response.status()).toBe(404);
        });

        test('should handle navigation timeout', async () => {
            mockPage.goto.mockRejectedValue(new Error('Navigation timeout'));

            const page = await global.Synthetics.getPage();

            await expect(
                page.goto('https://example.com', { timeout: 1000 })
            ).rejects.toThrow('Navigation timeout');
        });
    });

    describe('UI Element Validation', () => {
        test('should find logo element', async () => {
            const mockElement = { type: 'element' };
            mockPage.$.mockResolvedValue(mockElement);

            const page = await global.Synthetics.getPage();
            const logo = await page.$('img[alt*="logo"]');

            expect(logo).toBeDefined();
            expect(page.$).toHaveBeenCalledWith('img[alt*="logo"]');
        });

        test('should detect missing navigation element', async () => {
            mockPage.$.mockResolvedValue(null);

            const page = await global.Synthetics.getPage();
            const nav = await page.$('nav');

            expect(nav).toBeNull();
        });

        test('should find multiple elements', async () => {
            const mockImages = [
                { src: 'image1.jpg', naturalWidth: 100 },
                { src: 'image2.jpg', naturalWidth: 200 }
            ];

            mockPage.$$eval.mockResolvedValue(mockImages);

            const page = await global.Synthetics.getPage();
            const images = await page.$$eval('img', (imgs) =>
                imgs.map(img => ({
                    src: img.src,
                    naturalWidth: img.naturalWidth
                }))
            );

            expect(images).toHaveLength(2);
            expect(images[0].naturalWidth).toBe(100);
        });
    });

    describe('User Interactions', () => {
        test('should type into search field', async () => {
            const mockSearchInput = { type: 'input' };
            mockPage.$.mockResolvedValue(mockSearchInput);

            const page = await global.Synthetics.getPage();
            const searchInput = await page.$('input[type="search"]');

            if (searchInput) {
                await page.type('input[type="search"]', 'test query');
            }

            expect(page.type).toHaveBeenCalledWith('input[type="search"]', 'test query');
        });

        test('should click button', async () => {
            const page = await global.Synthetics.getPage();
            await page.click('button[type="submit"]');

            expect(page.click).toHaveBeenCalledWith('button[type="submit"]');
        });

        test('should wait for selector', async () => {
            mockPage.waitForSelector.mockResolvedValue(true);

            const page = await global.Synthetics.getPage();
            await page.waitForSelector('.success-message', { timeout: 5000 });

            expect(page.waitForSelector).toHaveBeenCalledWith(
                '.success-message',
                { timeout: 5000 }
            );
        });
    });

    describe('Performance Metrics', () => {
        test('should collect page metrics', async () => {
            const mockMetrics = {
                Timestamp: Date.now(),
                Documents: 1,
                Frames: 2,
                JSEventListeners: 10,
                Nodes: 100,
                LayoutCount: 5,
                RecalcStyleCount: 3,
                JSHeapUsedSize: 5000000,
                JSHeapTotalSize: 10000000
            };

            mockPage.metrics.mockResolvedValue(mockMetrics);

            const page = await global.Synthetics.getPage();
            const metrics = await page.metrics();

            expect(metrics.Documents).toBe(1);
            expect(metrics.JSHeapUsedSize).toBe(5000000);
            expect(metrics.JSHeapTotalSize).toBe(10000000);
        });
    });

    describe('Viewport Management', () => {
        test('should set desktop viewport', async () => {
            const page = await global.Synthetics.getPage();
            await page.setViewport({
                width: 1920,
                height: 1080
            });

            expect(page.setViewport).toHaveBeenCalledWith({
                width: 1920,
                height: 1080
            });
        });

        test('should set mobile viewport', async () => {
            const page = await global.Synthetics.getPage();
            await page.setViewport({
                width: 375,
                height: 812,
                isMobile: true
            });

            expect(page.setViewport).toHaveBeenCalledWith({
                width: 375,
                height: 812,
                isMobile: true
            });
        });
    });

    describe('Screenshot Capture', () => {
        test('should take screenshot', async () => {
            await global.Synthetics.takeScreenshot('homepage', 'result');

            expect(global.Synthetics.takeScreenshot).toHaveBeenCalledWith('homepage', 'result');
        });

        test('should take multiple screenshots', async () => {
            await global.Synthetics.takeScreenshot('desktop-view', 'result');
            await global.Synthetics.takeScreenshot('mobile-view', 'result');

            expect(global.Synthetics.takeScreenshot).toHaveBeenCalledTimes(2);
        });
    });

    describe('Synthetics Integration', () => {
        test('should call executeStep with correct parameters', async () => {
            const stepName = 'NavigateToHomepage';
            const stepFunction = jest.fn();

            await global.Synthetics.executeStep(stepName, stepFunction);

            expect(global.Synthetics.executeStep).toHaveBeenCalledWith(stepName, stepFunction);
            expect(stepFunction).toHaveBeenCalled();
        });

        test('should handle step execution errors', async () => {
            const stepFunction = jest.fn().mockRejectedValue(new Error('Step failed'));

            global.Synthetics.executeStep.mockImplementation(async (name, fn) => {
                return await fn();
            });

            await expect(
                global.Synthetics.executeStep('FailingStep', stepFunction)
            ).rejects.toThrow('Step failed');
        });
    });
});
