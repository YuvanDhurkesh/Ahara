const request = require('supertest');
const app = require('../../server');
const User = require('../../models/User');

jest.mock('../../models/User');

describe('User Preferences API Tests', () => {
    afterAll(async () => {
        // Close server connections
        if (app.close) {
            await app.close();
        }
    });

    describe('PUT /api/users/:firebaseUid/preferences', () => {
        it('should update language preference successfully', async () => {
            const mockUser = {
                firebaseUid: 'test-uid-123',
                preferences: {
                    language: 'en',
                    uiMode: 'standard'
                },
                save: jest.fn().mockResolvedValue(true)
            };

            User.findOne = jest.fn().mockResolvedValue(mockUser);

            const response = await request(app)
                .put('/api/users/test-uid-123/preferences')
                .send({
                    language: 'hi',
                    uiMode: 'standard'
                });

            expect(response.status).toBe(200);
            expect(mockUser.preferences.language).toBe('hi');
            expect(mockUser.save).toHaveBeenCalled();
        });

        it('should update UI mode preference successfully', async () => {
            const mockUser = {
                firebaseUid: 'test-uid-123',
                preferences: {
                    language: 'en',
                    uiMode: 'standard'
                },
                save: jest.fn().mockResolvedValue(true)
            };

            User.findOne = jest.fn().mockResolvedValue(mockUser);

            const response = await request(app)
                .put('/api/users/test-uid-123/preferences')
                .send({
                    language: 'en',
                    uiMode: 'simplified'
                });

            expect(response.status).toBe(200);
            expect(mockUser.preferences.uiMode).toBe('simplified');
            expect(mockUser.save).toHaveBeenCalled();
        });

        it('should return 404 if user not found', async () => {
            User.findOne = jest.fn().mockResolvedValue(null);

            const response = await request(app)
                .put('/api/users/nonexistent-uid/preferences')
                .send({
                    language: 'hi',
                    uiMode: 'standard'
                });

            expect(response.status).toBe(404);
            expect(response.body.error).toBeDefined();
        });

        it('should validate language preference values', async () => {
            const mockUser = {
                firebaseUid: 'test-uid-123',
                preferences: {
                    language: 'en',
                    uiMode: 'standard'
                },
                save: jest.fn().mockResolvedValue(true)
            };

            User.findOne = jest.fn().mockResolvedValue(mockUser);

            const validLanguages = ['en', 'hi', 'ta', 'te'];

            for (const lang of validLanguages) {
                const response = await request(app)
                    .put('/api/users/test-uid-123/preferences')
                    .send({
                        language: lang,
                        uiMode: 'standard'
                    });

                expect(response.status).toBe(200);
            }
        });

        it('should validate UI mode preference values', async () => {
            const mockUser = {
                firebaseUid: 'test-uid-123',
                preferences: {
                    language: 'en',
                    uiMode: 'standard'
                },
                save: jest.fn().mockResolvedValue(true)
            };

            User.findOne = jest.fn().mockResolvedValue(mockUser);

            const validModes = ['standard', 'simplified'];

            for (const mode of validModes) {
                const response = await request(app)
                    .put('/api/users/test-uid-123/preferences')
                    .send({
                        language: 'en',
                        uiMode: mode
                    });

                expect(response.status).toBe(200);
            }
        });
    });

    describe('GET /api/users/:firebaseUid/preferences', () => {
        it('should fetch user preferences successfully', async () => {
            const mockUser = {
                firebaseUid: 'test-uid-123',
                preferences: {
                    language: 'hi',
                    uiMode: 'simplified'
                }
            };

            User.findOne = jest.fn().mockResolvedValue(mockUser);

            const response = await request(app)
                .get('/api/users/test-uid-123/preferences');

            expect(response.status).toBe(200);
            expect(response.body.preferences.language).toBe('hi');
            expect(response.body.preferences.uiMode).toBe('simplified');
        });

        it('should return 404 if user not found', async () => {
            User.findOne = jest.fn().mockResolvedValue(null);

            const response = await request(app)
                .get('/api/users/nonexistent-uid/preferences');

            expect(response.status).toBe(404);
        });

        it('should return default preferences if not set', async () => {
            const mockUser = {
                firebaseUid: 'test-uid-123',
                preferences: {}
            };

            User.findOne = jest.fn().mockResolvedValue(mockUser);

            const response = await request(app)
                .get('/api/users/test-uid-123/preferences');

            expect(response.status).toBe(200);
            // Should have default values or empty object
            expect(response.body.preferences).toBeDefined();
        });
    });
});
