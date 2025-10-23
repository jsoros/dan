const synthetics = require('Synthetics');
const log = require('SyntheticsLogger');

/**
 * UI Monitoring Canary
 *
 * This canary performs visual monitoring of web pages using Puppeteer.
 * It captures screenshots, measures page load times, and validates UI elements.
 */

const uiCanaryBlueprint = async function () {
    // Configuration
    const config = {
        url: 'https://example.com',
        viewportWidth: 1920,
        viewportHeight: 1080,
        timeout: 30000
    };

    // Launch browser
    let page = await synthetics.getPage();

    // Configure page
    await page.setViewport({
        width: config.viewportWidth,
        height: config.viewportHeight
    });

    // Step 1: Navigate to homepage
    await synthetics.executeStep('NavigateToHomepage', async function () {
        const startTime = Date.now();

        const response = await page.goto(config.url, {
            waitUntil: 'networkidle0',
            timeout: config.timeout
        });

        const loadTime = Date.now() - startTime;
        log.info(`Page loaded in ${loadTime}ms`);

        // Validate response status
        if (!response || response.status() !== 200) {
            throw new Error(`Page returned status: ${response ? response.status() : 'unknown'}`);
        }

        // Take screenshot
        await synthetics.takeScreenshot('homepage', 'result');
    });

    // Step 2: Check critical UI elements
    await synthetics.executeStep('ValidateUIElements', async function () {
        // Example: Check if logo exists
        const logo = await page.$('img[alt*="logo"], .logo, #logo');
        if (!logo) {
            log.warn('Logo element not found');
        } else {
            log.info('✓ Logo element found');
        }

        // Example: Check if navigation exists
        const nav = await page.$('nav, .navigation, #navigation');
        if (!nav) {
            throw new Error('Navigation element not found');
        }
        log.info('✓ Navigation element found');

        // Example: Check if main content exists
        const main = await page.$('main, .main-content, #content');
        if (!main) {
            throw new Error('Main content element not found');
        }
        log.info('✓ Main content element found');
    });

    // Step 3: Test search functionality (example)
    await synthetics.executeStep('TestSearchFunctionality', async function () {
        // Look for search input
        const searchInput = await page.$('input[type="search"], input[name="search"], input[placeholder*="search"]');

        if (searchInput) {
            // Type search query
            await searchInput.type('test query');
            log.info('✓ Typed into search field');

            // Take screenshot of search
            await synthetics.takeScreenshot('search-input', 'result');

            // Optional: Submit search and validate results
            // const searchButton = await page.$('button[type="submit"]');
            // if (searchButton) {
            //     await searchButton.click();
            //     await page.waitForNavigation({ waitUntil: 'networkidle0' });
            //     await synthetics.takeScreenshot('search-results', 'result');
            // }
        } else {
            log.warn('Search input not found on page');
        }
    });

    // Step 4: Check page performance metrics
    await synthetics.executeStep('CheckPerformanceMetrics', async function () {
        const metrics = await page.metrics();

        log.info('Performance Metrics:');
        log.info(`  Timestamp: ${metrics.Timestamp}`);
        log.info(`  Documents: ${metrics.Documents}`);
        log.info(`  Frames: ${metrics.Frames}`);
        log.info(`  JSEventListeners: ${metrics.JSEventListeners}`);
        log.info(`  Nodes: ${metrics.Nodes}`);
        log.info(`  LayoutCount: ${metrics.LayoutCount}`);
        log.info(`  RecalcStyleCount: ${metrics.RecalcStyleCount}`);
        log.info(`  JSHeapUsedSize: ${(metrics.JSHeapUsedSize / 1024 / 1024).toFixed(2)} MB`);
        log.info(`  JSHeapTotalSize: ${(metrics.JSHeapTotalSize / 1024 / 1024).toFixed(2)} MB`);
    });

    // Step 5: Test responsive design (optional)
    await synthetics.executeStep('TestMobileView', async function () {
        // Switch to mobile viewport
        await page.setViewport({
            width: 375,
            height: 812,
            isMobile: true
        });

        await page.reload({ waitUntil: 'networkidle0' });

        // Take screenshot of mobile view
        await synthetics.takeScreenshot('mobile-view', 'result');

        log.info('✓ Mobile view captured');
    });
};

exports.handler = async () => {
    return await uiCanaryBlueprint();
};
