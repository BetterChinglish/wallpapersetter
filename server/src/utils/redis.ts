import { createClient, RedisClientType } from 'redis';

// 创建 Redis 客户端
const redisClient = createClient({
  socket: {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT || '6379'),
  },
  // 只有当密码非空时才设置
  ...(process.env.REDIS_PASSWORD && { password: process.env.REDIS_PASSWORD }),
});

// 错误处理
redisClient.on('error', (err) => {
  console.error('❌ Redis Client Error:', err);
});

redisClient.on('connect', () => {
  console.log('✅ Redis connected');
});

// 连接 Redis
export async function connectRedis() {
  if (!redisClient.isOpen) {
    await redisClient.connect();
  }
  return redisClient;
}

// 断开连接
export async function disconnectRedis() {
  if (redisClient.isOpen) {
    await redisClient.quit();
  }
}

// 导出 redis 客户端（单例）
export const redis = redisClient;
