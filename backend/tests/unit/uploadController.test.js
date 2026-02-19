const uploadController = require('../../controllers/uploadController');
const httpMocks = require('node-mocks-http');

// ─────────────────────────────────────────────
// sendUploadResponse
// ─────────────────────────────────────────────
describe('Upload Controller - sendUploadResponse', () => {
    let req, res;

    beforeEach(() => {
        req = httpMocks.createRequest();
        res = httpMocks.createResponse();
    });

    it('should return 400 if no file is uploaded', () => {
        // req.file is undefined by default (no file in request)
        uploadController.sendUploadResponse(req, res);

        expect(res.statusCode).toBe(400);
        expect(res._getJSONData().error).toBe('No file uploaded');
    });

    it('should return 200 with imageUrl if file is uploaded', () => {
        req.file = {
            filename: 'image-12345-67890.jpg',
            path: 'uploads/image-12345-67890.jpg',
            mimetype: 'image/jpeg',
            size: 102400
        };

        uploadController.sendUploadResponse(req, res);

        expect(res.statusCode).toBe(200);

        const body = res._getJSONData();
        expect(body.message).toBe('Image uploaded successfully');
        expect(body.imageUrl).toBe('/uploads/image-12345-67890.jpg');
    });

    it('should include the filename in the imageUrl', () => {
        req.file = {
            filename: 'image-unique-name.png',
            path: 'uploads/image-unique-name.png',
            mimetype: 'image/png',
            size: 51200
        };

        uploadController.sendUploadResponse(req, res);

        const body = res._getJSONData();
        expect(body.imageUrl).toContain('image-unique-name.png');
    });

    it('should always prefix imageUrl with /uploads/', () => {
        req.file = {
            filename: 'some-other-file.webp',
            path: 'uploads/some-other-file.webp',
            mimetype: 'image/webp',
            size: 204800
        };

        uploadController.sendUploadResponse(req, res);

        const body = res._getJSONData();
        expect(body.imageUrl.startsWith('/uploads/')).toBe(true);
    });
});

// ─────────────────────────────────────────────
// uploadImage middleware existence
// ─────────────────────────────────────────────
describe('Upload Controller - uploadImage middleware', () => {
    it('should export uploadImage as a function (multer middleware)', () => {
        expect(typeof uploadController.uploadImage).toBe('function');
    });
});
