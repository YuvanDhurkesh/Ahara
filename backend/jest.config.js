const dotenv = require('dotenv');

// Load .env.test for test environment
if (process.env.NODE_ENV === 'test') {
    dotenv.config({ path: '.env.test' });
}

// Disable MD5 check for mongodb-memory-server (upstream checkfile mismatch for 6.0.4)
process.env.MONGOMS_MD5_CHECK = '0';

module.exports = {
    testEnvironment: 'node',
    verbose: true,
    setupFilesAfterEnv: ['./tests/setup.js', './tests/jest.setup.js'],
    testTimeout: 60000, // 60 seconds for integration tests
    maxWorkers: 1, // Run tests sequentially to avoid database conflicts
    collectCoverageFrom: [
        'controllers/**/*.js',
        'models/**/*.js',
        'utils/**/*.js',
        'routes/**/*.js',
        '!**/node_modules/**',
        '!**/tests/**',
    ],
    testMatch: [
        '**/tests/**/*.test.js',
    ],
};
