import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { prisma } from '../utils/prisma';

// 扩展 Express Request 类型
declare global {
  namespace Express {
    interface Request {
      user?: {
        userId: string;
        openId: string;
        nickname?: string;
      };
    }
  }
}

export interface AuthRequest extends Request {
  user?: {
    userId: string;
    openId: string;
    nickname?: string;
  };
}

/**
 * JWT 认证中间件
 * 验证 Authorization: Bearer <token> 头
 */
export async function authMiddleware(
  req: Request,
  res: Response,
  next: NextFunction
) {
  try {
    // 从 Header 获取 Token
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        code: 'UNAUTHORIZED',
        message: '未提供认证令牌',
      });
    }

    const token = authHeader.substring(7);

    // 验证 Token
    const decoded = jwt.verify(token, process.env.JWT_SECRET!) as {
      userId: string;
      openId: string;
    };

    // 查询用户是否存在
    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: { id: true, openId: true, nickname: true, isActive: true },
    });

    if (!user || !user.isActive) {
      return res.status(401).json({
        code: 'USER_NOT_FOUND',
        message: '用户不存在或已被禁用',
      });
    }

    // 将用户信息附加到请求对象
    req.user = {
      userId: user.id,
      openId: user.openId,
      nickname: user.nickname || undefined,
    };

    next();
  } catch (error) {
    if (error instanceof jwt.TokenExpiredError) {
      return res.status(401).json({
        code: 'TOKEN_EXPIRED',
        message: '认证令牌已过期',
      });
    }

    if (error instanceof jwt.JsonWebTokenError) {
      return res.status(401).json({
        code: 'TOKEN_INVALID',
        message: '认证令牌无效',
      });
    }

    console.error('Auth middleware error:', error);
    return res.status(500).json({
      code: 'INTERNAL_ERROR',
      message: '认证服务异常',
    });
  }
}

/**
 * 可选认证中间件
 * 有 Token 就验证，没有就跳过（用于公开 API）
 */
export async function optionalAuthMiddleware(
  req: Request,
  _res: Response,
  next: NextFunction
) {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next();
  }

  try {
    const token = authHeader.substring(7);
    const decoded = jwt.verify(token, process.env.JWT_SECRET!) as {
      userId: string;
      openId: string;
    };

    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: { id: true, openId: true, nickname: true, isActive: true },
    });

    if (user && user.isActive) {
      req.user = {
        userId: user.id,
        openId: user.openId,
        nickname: user.nickname || undefined,
      };
    }
  } catch {
    // Token 无效，但不阻止请求
  }

  next();
}
