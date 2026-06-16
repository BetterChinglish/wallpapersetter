import { Router, Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { prisma } from '../utils/prisma';
import { redis } from '../utils/redis';
import { minioClient, BUCKET_NAME, getFileUrl } from '../utils/minio';

const router = Router();

/**
 * 生成微信登录二维码
 * GET /api/auth/wechat/qrcode
 */
router.get('/wechat/qrcode', async (_req: Request, res: Response) => {
  try {
    // 生成唯一的场景值（用于微信回调时识别）
    const sceneId = `wallpaper_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    // 存储场景值到 Redis（过期时间 5 分钟）
    await redis.setex(`wechat_auth:${sceneId}`, 300, JSON.stringify({
      status: 'pending',
      createdAt: Date.now(),
    }));

    // 返回二维码数据（实际对接微信开放平台时需要替换为真实 URL）
    // 开发阶段使用模拟数据
    const qrcodeUrl = `https://open.weixin.qq.com/connect/oauth2/authorize?appid=${process.env.WECHAT_APPID}&redirect_uri=${encodeURIComponent(process.env.WECHAT_REDIRECT_URL!)}&response_type=code&scope=snsapi_userinfo&state=${sceneId}#wechat_redirect`;

    res.json({
      code: 'SUCCESS',
      data: {
        sceneId,
        qrcodeUrl,
        expiresIn: 300,
      },
    });
  } catch (error) {
    console.error('Generate QR code error:', error);
    res.status(500).json({
      code: 'INTERNAL_ERROR',
      message: '生成二维码失败',
    });
  }
});

/**
 * 轮询登录状态
 * GET /api/auth/wechat/poll?sceneId=xxx
 */
router.get('/wechat/poll', async (req: Request, res: Response) => {
  try {
    const { sceneId } = req.query;

    if (!sceneId || typeof sceneId !== 'string') {
      return res.status(400).json({
        code: 'INVALID_PARAM',
        message: '缺少 sceneId 参数',
      });
    }

    // 从 Redis 查询登录状态
    const authData = await redis.get(`wechat_auth:${sceneId}`);
    
    if (!authData) {
      return res.status(404).json({
        code: 'QRCODE_EXPIRED',
        message: '二维码已过期',
      });
    }

    const authInfo = JSON.parse(authData);

    if (authInfo.status === 'pending') {
      return res.json({
        code: 'PENDING',
        message: '等待扫码',
      });
    }

    if (authInfo.status === 'authorized') {
      // 生成 JWT Token
      const token = jwt.sign(
        {
          userId: authInfo.userId,
          openId: authInfo.openId,
        },
        process.env.JWT_SECRET!,
        { expiresIn: '7d' }
      );

      // 清除 Redis 中的临时数据
      await redis.del(`wechat_auth:${sceneId}`);

      return res.json({
        code: 'SUCCESS',
        data: {
          token,
          user: {
            id: authInfo.userId,
            nickname: authInfo.nickname,
            avatarUrl: authInfo.avatarUrl,
          },
        },
      });
    }

    res.json({
      code: 'PENDING',
      message: '等待扫码',
    });
  } catch (error) {
    console.error('Poll auth error:', error);
    res.status(500).json({
      code: 'INTERNAL_ERROR',
      message: '查询登录状态失败',
    });
  }
});

/**
 * 微信回调接口（生产环境使用）
 * GET /api/auth/wechat/callback?code=xxx&state=xxx
 */
router.get('/wechat/callback', async (req: Request, res: Response) => {
  try {
    const { code, state } = req.query;

    if (!code || !state) {
      return res.status(400).send('参数错误');
    }

    // TODO: 调用微信 API 获取用户信息
    // 1. 用 code 换 access_token
    // 2. 用 access_token 获取用户信息
    // 3. 根据 openId 查找或创建用户
    // 4. 更新 Redis 中的登录状态
    // 5. 返回成功页面

    // 开发阶段模拟成功
    res.send(`
      <html>
        <body>
          <h1>登录成功！</h1>
          <p>请关闭此窗口，返回应用。</p>
          <script>
            setTimeout(() => window.close(), 2000);
          </script>
        </body>
      </html>
    `);
  } catch (error) {
    console.error('Wechat callback error:', error);
    res.status(500).send('登录失败');
  }
});

/**
 * 退出登录
 * POST /api/auth/logout
 */
router.post('/logout', async (req: Request, res: Response) => {
  try {
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.substring(7);
      
      // 将 Token 加入黑名单（1 小时后过期）
      await redis.setex(`token_blacklist:${token}`, 3600, '1');
    }

    res.json({
      code: 'SUCCESS',
      message: '退出成功',
    });
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({
      code: 'INTERNAL_ERROR',
      message: '退出失败',
    });
  }
});

export default router;
