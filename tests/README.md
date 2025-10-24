# Tests

This directory contains unit tests for the AWS Synthetics canary scripts.

## Overview

The test suite uses Jest to test the canary logic and ensure code quality. Tests are mocked to avoid requiring actual AWS services or network connections.

## Running Tests

### All Tests

```bash
npm test
# Or
make test
```

### Watch Mode

Run tests in watch mode for development:

```bash
npm run test:watch
# Or
make test-watch
```

### Coverage Report

Generate a coverage report:

```bash
npm run test:coverage
# Or
make test-coverage
```

This will create a `coverage/` directory with detailed coverage reports. Open `coverage/lcov-report/index.html` in your browser to view the report.

## Test Structure

```
tests/
├── setup.js              # Global test setup and mocks
├── apiMonitor.test.js    # Tests for API monitor canary
├── uiMonitor.test.js     # Tests for UI monitor canary
└── heartbeat.test.js     # Tests for heartbeat canary
```

## Writing Tests

### Test File Naming

- Test files should be named `*.test.js`
- Place test files in the `tests/` directory
- Name tests after the module they test (e.g., `apiMonitor.test.js` tests `canaries/api-monitor/apiMonitor.js`)

### Test Structure

```javascript
describe('Feature Name', () => {
    beforeEach(() => {
        // Setup before each test
        jest.clearAllMocks();
    });

    test('should do something specific', async () => {
        // Arrange
        const input = 'test';

        // Act
        const result = await functionToTest(input);

        // Assert
        expect(result).toBe('expected');
    });
});
```

### Mocking AWS Synthetics

The `setup.js` file provides global mocks for:

- `Synthetics` - AWS Synthetics API
- `SyntheticsLogger` - Logging functions

Example usage in tests:

```javascript
test('should execute step', async () => {
    await Synthetics.executeStep('StepName', async () => {
        // Step logic
    });

    expect(Synthetics.executeStep).toHaveBeenCalledWith(
        'StepName',
        expect.any(Function)
    );
});
```

### Mocking Page Operations

```javascript
beforeEach(() => {
    mockPage = {
        goto: jest.fn(),
        $: jest.fn(),
        type: jest.fn(),
        click: jest.fn()
    };

    Synthetics.getPage.mockResolvedValue(mockPage);
});

test('should navigate to page', async () => {
    const page = await Synthetics.getPage();
    await page.goto('https://example.com');

    expect(page.goto).toHaveBeenCalledWith('https://example.com');
});
```

### Testing HTTP Requests

```javascript
const https = require('https');
const EventEmitter = require('events');

beforeEach(() => {
    mockRequest = new EventEmitter();
    mockResponse = new EventEmitter();
    mockResponse.statusCode = 200;

    https.request = jest.fn((options, callback) => {
        setImmediate(() => callback(mockResponse));
        return mockRequest;
    });
});

test('should make HTTP request', async () => {
    // Your test logic
    const testPromise = makeRequest();

    setImmediate(() => {
        mockResponse.emit('data', 'response body');
        mockResponse.emit('end');
    });

    await expect(testPromise).resolves.toBeDefined();
});
```

## Coverage Thresholds

The project enforces minimum coverage thresholds:

- **Branches**: 70%
- **Functions**: 70%
- **Lines**: 70%
- **Statements**: 70%

If coverage falls below these thresholds, tests will fail.

## Best Practices

1. **Test Behavior, Not Implementation**
   - Focus on what the code does, not how it does it
   - Test public interfaces, not internal implementation details

2. **Use Descriptive Test Names**
   ```javascript
   // Good
   test('should fail when status code does not match expected', ...)

   // Bad
   test('test 1', ...)
   ```

3. **Follow AAA Pattern**
   - **Arrange**: Set up test data and mocks
   - **Act**: Execute the function being tested
   - **Assert**: Verify the results

4. **Keep Tests Independent**
   - Each test should run independently
   - Use `beforeEach` for setup
   - Use `afterEach` for cleanup

5. **Mock External Dependencies**
   - Mock AWS services
   - Mock network requests
   - Mock file system operations

6. **Test Error Cases**
   - Test both success and failure paths
   - Test edge cases
   - Test error handling

## Common Patterns

### Testing Async Functions

```javascript
test('should handle async operations', async () => {
    const result = await asyncFunction();
    expect(result).toBe('expected');
});
```

### Testing Promises

```javascript
test('should resolve promise', async () => {
    await expect(promiseFunction()).resolves.toBe('value');
});

test('should reject promise', async () => {
    await expect(promiseFunction()).rejects.toThrow('error message');
});
```

### Testing Errors

```javascript
test('should throw error', () => {
    expect(() => functionThatThrows()).toThrow('error message');
});

test('should handle error in async function', async () => {
    await expect(asyncFunctionThatFails()).rejects.toThrow('error message');
});
```

### Testing Timeouts

```javascript
test('should handle timeout', async () => {
    const testPromise = functionWithTimeout();

    setImmediate(() => {
        mockRequest.emit('timeout');
    });

    await expect(testPromise).rejects.toThrow('timeout');
});
```

## Debugging Tests

### Run Specific Test

```bash
npm test -- apiMonitor.test.js
```

### Run Tests Matching Pattern

```bash
npm test -- --testNamePattern="should successfully"
```

### Verbose Output

```bash
npm run test:verbose
```

### Debug in VS Code

Add to `.vscode/launch.json`:

```json
{
    "type": "node",
    "request": "launch",
    "name": "Jest Debug",
    "program": "${workspaceFolder}/node_modules/.bin/jest",
    "args": ["--runInBand", "--no-cache"],
    "console": "integratedTerminal",
    "internalConsoleOptions": "neverOpen"
}
```

## CI/CD Integration

Tests run automatically on:
- Push to `main` or `master` branches
- Pull requests
- Push to branches starting with `claude/`

See `.github/workflows/ci.yml` for CI configuration.

## Troubleshooting

### Tests Timing Out

Increase Jest timeout:

```javascript
jest.setTimeout(10000); // 10 seconds
```

### Mock Not Working

Ensure mocks are defined before requiring modules:

```javascript
// Define mocks first
jest.mock('module-name');

// Then require
const module = require('module-name');
```

### Coverage Not Accurate

Clear Jest cache:

```bash
npm test -- --clearCache
```

## Resources

- [Jest Documentation](https://jestjs.io/docs/getting-started)
- [Jest Matchers](https://jestjs.io/docs/expect)
- [Mocking with Jest](https://jestjs.io/docs/mock-functions)
- [Testing Asynchronous Code](https://jestjs.io/docs/asynchronous)
