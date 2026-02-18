const dotenv = require('dotenv');

// Load .env.test for test environment
if (process.env.NODE_ENV === 'test') {
    dotenv.config({ path: '.env.test' });
}

module.exports = {
    testEnvironment: 'node',
    verbose: true,
    setupFilesAfterEnv: ['./tests/setup.js'],
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
