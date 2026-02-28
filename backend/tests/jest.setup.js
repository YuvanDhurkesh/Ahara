/**
 * Jest global setup: silence noisy console output during test runs.
 *
 * The controllers print console.log/warn/error for every request — even
 * intentionally-rejected ones (missing field, listing not found, etc.).
 * These are expected and the tests assert the HTTP status codes/bodies,
 * so the log spam is pure noise.  We suppress it here and restore the
 * originals after each test suite so nothing leaks between suites.
 */

const originalConsole = {
    log: console.log,
    warn: console.warn,
    error: console.error,
};

beforeAll(() => {
    // Suppress everything except critical infra messages (✅/❌ prefixed)
    console.log = (...args) => {
        const msg = args[0]?.toString() ?? '';
        if (msg.startsWith('✅') || msg.startsWith('❌')) {
            originalConsole.log(...args);
        }
    };
    console.warn = () => { };
    console.error = (...args) => {
        const msg = args[0]?.toString() ?? '';
        // Only show true infrastructure failures, not controller validation logs
        if (msg.startsWith('❌')) {
            originalConsole.error(...args);
        }
    };
});

afterAll(() => {
    console.log = originalConsole.log;
    console.warn = originalConsole.warn;
    console.error = originalConsole.error;
});
