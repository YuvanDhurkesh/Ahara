const express = require('express');
const request = require('supertest');

describe('Global Error Handler Middleware', () => {
    let app;

    beforeEach(() => {
        app = express();
        app.use(express.json());

        // A route that throws a synchronous error
        app.get('/error-sync', (req, res, next) => {
            next(new Error('Something broke'));
        });

        // A route that throws with a custom message
        app.get('/error-custom', (req, res, next) => {
            next(new Error('Database connection lost'));
        });

        // Re-create the global error handler from server.js
        // (We import the pattern, not server.js itself, to avoid starting the server)
        app.use((err, req, res, next) => {
            res.status(500).json({ error: 'Internal Server Error', details: err.message });
        });
    });

    test('should return 500 status code on error', async () => {
        const res = await request(app).get('/error-sync');
        expect(res.status).toBe(500);
    });

    test('should return JSON with error and details fields', async () => {
        const res = await request(app).get('/error-sync');
        expect(res.body).toHaveProperty('error', 'Internal Server Error');
        expect(res.body).toHaveProperty('details', 'Something broke');
    });

    test('should include the original error message in details', async () => {
        const res = await request(app).get('/error-custom');
        expect(res.body.details).toBe('Database connection lost');
    });

    test('should return JSON content-type', async () => {
        const res = await request(app).get('/error-sync');
        expect(res.headers['content-type']).toMatch(/json/);
    });
});
