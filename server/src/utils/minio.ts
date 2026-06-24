import * as Minio from 'minio';

const minioClient = new Minio.Client({
  endPoint: process.env.MINIO_ENDPOINT || 'localhost',
  port: parseInt(process.env.MINIO_PORT || '9000'),
  useSSL: process.env.MINIO_USE_SSL === 'true',
  accessKey: process.env.MINIO_ACCESS_KEY || 'myadmin',
  secretKey: process.env.MINIO_SECRET_KEY || 'myadminpwd',
});

export async function ensureBucketExists(bucketName: string) {
  const exists = await minioClient.bucketExists(bucketName);
  if (!exists) {
    await minioClient.makeBucket(bucketName, 'us-east-1');
    console.log(`✅ Bucket '${bucketName}' created`);
  }
}

export async function uploadFile(
  bucketName: string,
  objectName: string,
  filePath: string,
  metaData?: Record<string, string>
) {
  await minioClient.fPutObject(bucketName, objectName, filePath, metaData || {});
  const url = `/${bucketName}/${objectName}`;
  return url;
}

export async function getFileUrl(bucketName: string, objectName: string) {
  return await minioClient.presignedGetObject(bucketName, objectName, 24 * 60 * 60); // 24 hours
}

export async function deleteFile(bucketName: string, objectName: string) {
  await minioClient.removeObject(bucketName, objectName);
}

export { minioClient };

// Re-export bucket name as a constant for callers that need it without
// having to thread it through every function. Reads from env so it stays
// in sync with .env / docker-compose configuration.
export const BUCKET_NAME = process.env.MINIO_BUCKET_NAME || 'wallpapers';
