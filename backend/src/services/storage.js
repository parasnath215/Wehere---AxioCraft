const fs = require('fs');
const path = require('path');
const sharp = require('sharp');
const { v4: uuidv4 } = require('uuid');

const UPLOADS_DIR = path.join(__dirname, '../../public/uploads');

// Ensure uploads directory exists
if (!fs.existsSync(UPLOADS_DIR)) {
  fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}

const ALLOWED_FORMATS = ['jpeg', 'png', 'webp', 'jpg'];

/**
 * Process and save an image buffer using sharp.
 * @param {Buffer} buffer - The image buffer
 * @returns {Promise<string>} - The saved filename/URL path
 */
async function processAndSaveImage(buffer) {
  try {
    // Read metadata to validate decodability and get format
    const metadata = await sharp(buffer).metadata();
    
    if (!metadata || !ALLOWED_FORMATS.includes(metadata.format)) {
      throw new Error(`Unsupported image format: ${metadata.format}`);
    }

    const filename = `${uuidv4()}.webp`; // Always save as webp
    const filePath = path.join(UPLOADS_DIR, filename);

    // Process image:
    // 1. auto-rotate (reads EXIF Orientation, rotates, then strips all EXIF)
    // 2. resize to max 1440px on long side (without enlarging)
    // 3. encode as webp with quality 80
    await sharp(buffer)
      .rotate() 
      .resize({
        width: 1440,
        height: 1440,
        fit: sharp.fit.inside,
        withoutEnlargement: true
      })
      .webp({ quality: 80 })
      .toFile(filePath);

    return `/uploads/${filename}`;
  } catch (error) {
    throw new Error('Image processing failed: ' + error.message);
  }
}

/**
 * Delete an image file from storage given its URL
 * @param {string} url - The URL like /uploads/xxxx.webp
 */
function deleteImage(url) {
  if (!url) return;
  const filename = path.basename(url);
  const filePath = path.join(UPLOADS_DIR, filename);
  if (fs.existsSync(filePath)) {
    try {
      fs.unlinkSync(filePath);
    } catch (e) {
      console.error('Failed to delete file:', filePath, e);
    }
  }
}

module.exports = {
  processAndSaveImage,
  deleteImage,
  UPLOADS_DIR
};
