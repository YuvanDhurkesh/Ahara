const request = require('supertest');
const app = require('../../server');
const fs = require('fs');
const path = require('path');

describe('Upload Routes Integration Tests', () => {
    const uploadDir = 'uploads/';

    // Cleanup uploads directory after tests
    afterAll(() => {
        // Optional: delete test files if needed
    });

    it('POST /api/upload should upload an image', async () => {
        const res = await request(app)
            .post('/api/upload')
            .attach('image', Buffer.from('mock image data'), 'test.png');

        expect(res.statusCode).toBe(200);
        expect(res.body.message).toBe('Image uploaded successfully');
        expect(res.body.imageUrl).toContain('/uploads/image-');

        // Verify file exists
        const filename = res.body.imageUrl.replace('/uploads/', '');
        const filePath = path.join(uploadDir, filename);
        expect(fs.existsSync(filePath)).toBe(true);

        // Cleanup
        if (fs.existsSync(filePath)) {
            fs.unlinkSync(filePath);
        }
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
