/**
 * Jest global setup: silence noisy console output during test runs.
 *
 * The controllers print console.log/warn/error for every request — even
 * intentionally-rejected ones (missing field, listing not found, etc.).
 * These are expected and the tests assert the HTTP status codes/bodies,
 * so the log spam is pure noise.  We suppress it here and restore the
 * originals after each test suite so nothing leaks between suites.
 */

// ── Suppress Mongoose deprecation warnings (emitted via process.warning) ──
const _origEmit = process.emitWarning;
process.emitWarning = function (msg, ...rest) {
    if (typeof msg === 'string' && msg.includes('mongoose')) return;
    return _origEmit.call(this, msg, ...rest);
};

// ── Suppress dotenv injection log ──
process.env.DOTENV_CONFIG_QUIET = 'true';

const originalConsole = {
    log: console.log,
    warn: console.warn,
    error: console.error,
};

// ── Immediately suppress noisy module-load logs (Razorpay key, dotenv) ──
console.log = (...args) => {
    const msg = args[0]?.toString() ?? '';
    if (msg.startsWith('✅') || msg.startsWith('❌')) {
        originalConsole.log(...args);
    }
};
console.warn = () => { };
console.error = () => { };

beforeAll(() => {
    // Re-apply in case another setup file restored them
    console.log = (...args) => {
        const msg = args[0]?.toString() ?? '';
        if (msg.startsWith('✅') || msg.startsWith('❌')) {
            originalConsole.log(...args);
        }
    };
    console.warn = () => { };
    console.error = (...args) => {
        // Suppress all controller errors during tests — they are expected
    };
});

afterAll(() => {
    console.log = originalConsole.log;
    console.warn = originalConsole.warn;
    console.error = originalConsole.error;
});
