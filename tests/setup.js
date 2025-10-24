// Mock AWS Synthetics modules
global.Synthetics = {
    executeStep: jest.fn((name, fn) => fn()),
    getPage: jest.fn(),
    addUserAgentHeader: jest.fn(),
    takeScreenshot: jest.fn()
};

global.SyntheticsLogger = {
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
    debug: jest.fn()
};

// Mock https and http modules
jest.mock('https');
jest.mock('http');
