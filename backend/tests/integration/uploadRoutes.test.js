// Mock Cloudinary and its multer storage BEFORE requiring the app/controller
jest.mock('cloudinary', () => ({
    v2: {
        config: jest.fn(),
        uploader: { upload: jest.fn() },
    },
}));

jest.mock('multer-storage-cloudinary', () => {
    const multer = require('multer');
    // Replace CloudinaryStorage with plain memoryStorage so no real upload happens
    return { CloudinaryStorage: jest.fn(() => multer.memoryStorage()) };
});

const request = require('supertest');
const app = require('../../server');

describe('Upload Routes Integration Tests', () => {
    it('POST /api/upload should upload an image', async () => {
        const res = await request(app)
            .post('/api/upload')
            .attach('image', Buffer.from('mock image data'), 'test.png');

        expect(res.statusCode).toBe(200);
        expect(res.body.message).toBe('Image uploaded successfully');
        // With memoryStorage req.file.path is undefined; our controller sets imageUrl
        // from req.file.path – so this test only asserts a 200 and the message key.
        // The /uploads/ prefix is validated thoroughly in the unit tests.
    });

    it('POST /api/upload should fail if no file is uploaded', async () => {
        const res = await request(app)
            .post('/api/upload');

        expect(res.statusCode).toBe(400);
        expect(res.body.error).toBe('No file uploaded');
    });

    it('POST /api/upload should fail with non-image file', async () => {
        const res = await request(app)
            .post('/api/upload')
            .attach('image', Buffer.from('mock text data'), 'test.txt');

        expect(res.statusCode).toBe(400);
        expect(res.body.error).toBe('Only image files are allowed');
    });
});
