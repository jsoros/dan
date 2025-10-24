const synthetics = require('Synthetics');
const log = require('SyntheticsLogger');

/**
 * Heartbeat Canary
 *
 * Simple health check canary that monitors basic availability of services.
 * Ideal for simple uptime monitoring.
 */

const heartbeatBlueprint = async function () {
    // URLs to monitor
    const urls = [
        'https://example.com',
        'https://api.example.com/health'
        // Add more URLs as needed
    ];

    for (const url of urls) {
        await checkUrl(url);
    }
};

async function checkUrl(url) {
    const stepName = `Check ${new URL(url).hostname}`;

    await synthetics.executeStep(stepName, async function () {
        const page = await synthetics.getPage();

        // Set a reasonable timeout
        page.setDefaultNavigationTimeout(10000);

        log.info(`Checking URL: ${url}`);

        const startTime = Date.now();
        const response = await page.goto(url, {
            waitUntil: 'domcontentloaded',
            timeout: 10000
        });
        const duration = Date.now() - startTime;

        const statusCode = response.status();
        log.info(`Response: ${statusCode} in ${duration}ms`);

        // Validate response
        if (statusCode < 200 || statusCode >= 400) {
            throw new Error(`Health check failed with status: ${statusCode}`);
        }

        // Take screenshot for visual verification
        await synthetics.takeScreenshot(new URL(url).hostname, 'result');

        log.info(`✓ ${url} is healthy (${duration}ms)`);
    });
}

exports.handler = async () => {
    return await heartbeatBlueprint();
};
