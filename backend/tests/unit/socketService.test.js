const socketService = require('../../services/socketService');

// ─────────────────────────────────────────────
// Socket Service
// ─────────────────────────────────────────────
describe('Socket Service', () => {
    it('should export an init function', () => {
        expect(typeof socketService.init).toBe('function');
    });

    it('should export a getIo function', () => {
        expect(typeof socketService.getIo).toBe('function');
    });

    it('should throw error when getIo is called before init', () => {
        expect(() => socketService.getIo()).toThrow(/not initialized/i);
    });
});
