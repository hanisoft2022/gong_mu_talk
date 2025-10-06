import {onObjectFinalized} from "firebase-functions/v2/storage";
import {getStorage} from "firebase-admin/storage";
import * as path from "path";
import * as os from "os";
import * as fs from "fs";
import sharp from "sharp";

/**
 * Configuration for thumbnail generation
 */
const THUMBNAIL_CONFIG = {
  // Thumbnail dimensions (square)
  width: 300,
  height: 300,
  
  // WebP compression quality
  quality: 75,
  
  // Thumbnail prefix
  prefix: "thumb_",
  
  // Paths to process (only post and comment images)
  validPaths: ["post_images/", "comment_images/"],
};

/**
 * Generate thumbnail when image is uploaded to Firebase Storage.
 * 
 * Triggers on:
 * - post_images/{userId}/{postId}/{fileName}
 * - comment_images/{userId}/{commentId}/{fileName}
 * 
 * Creates:
 * - Same path with thumb_ prefix
 * - 300x300 WebP thumbnail
 * - 7-day CDN caching
 */
export const generateThumbnail = onObjectFinalized(
  {
    region: "us-central1",
  },
  async (event) => {
    const filePath = event.data.name;
    const contentType = event.data.contentType;

    // Skip if not an image
    if (!contentType || !contentType.startsWith("image/")) {
      console.log(`Skipping non-image file: ${filePath}`);
      return;
    }

    // Skip if already a thumbnail
    const fileName = path.basename(filePath);
    if (fileName.startsWith(THUMBNAIL_CONFIG.prefix)) {
      console.log(`Skipping thumbnail file: ${filePath}`);
      return;
    }

    // Only process post_images and comment_images
    const isValidPath = THUMBNAIL_CONFIG.validPaths.some((validPath) =>
      filePath.startsWith(validPath)
    );
    if (!isValidPath) {
      console.log(`Skipping file outside valid paths: ${filePath}`);
      return;
    }

    try {
      console.log(`Generating thumbnail for: ${filePath}`);

      const bucket = getStorage().bucket(event.data.bucket);
      const file = bucket.file(filePath);

      // Create temp file paths
      const tempDir = os.tmpdir();
      const tempFilePath = path.join(tempDir, fileName);
      const tempThumbPath = path.join(
        tempDir,
        `${THUMBNAIL_CONFIG.prefix}${fileName}`
      );

      // Download original image
      await file.download({destination: tempFilePath});
      console.log(`Downloaded original image to: ${tempFilePath}`);

      // Generate thumbnail using sharp
      await sharp(tempFilePath)
        .resize(THUMBNAIL_CONFIG.width, THUMBNAIL_CONFIG.height, {
          fit: "cover",
          position: "center",
        })
        .webp({quality: THUMBNAIL_CONFIG.quality})
        .toFile(tempThumbPath);

      console.log(`Generated thumbnail: ${tempThumbPath}`);

      // Upload thumbnail to same directory as original
      const fileDir = path.dirname(filePath);
      const thumbFileName = `${THUMBNAIL_CONFIG.prefix}${fileName.replace(/\.[^/.]+$/, "")}.webp`;
      const thumbFilePath = path.join(fileDir, thumbFileName);

      await bucket.upload(tempThumbPath, {
        destination: thumbFilePath,
        metadata: {
          contentType: "image/webp",
          metadata: {
            originalFile: filePath,
            thumbnailGenerated: new Date().toISOString(),
          },
          // CDN caching: 7 days (same as original images)
          cacheControl: "public, max-age=604800",
        },
      });

      console.log(`Uploaded thumbnail to: ${thumbFilePath}`);

      // Clean up temp files
      fs.unlinkSync(tempFilePath);
      fs.unlinkSync(tempThumbPath);

      console.log(`Successfully generated thumbnail for: ${filePath}`);
    } catch (error) {
      console.error(`Error generating thumbnail for ${filePath}:`, error);
      throw error;
    }
  }
);
