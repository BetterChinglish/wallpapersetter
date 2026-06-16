import { Router, Request, Response } from 'express';
import multer from 'multer';
import { minioClient, BUCKET_NAME, getFileUrl } from '../utils/minio';
import { prisma } from '../utils/prisma';
import { redis } from '../utils/redis';

const router = Router();

// 配置 Multer（内存存储，直接上传到 MinIO）
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB 限制
  },
  fileFilter: (_req, file, cb) => {
    // 只允许上传 HTML 文件
    if (file.mimetype === 'text/html' || file.originalname.endsWith('.html')) {
      cb(null, true);
    } else {
      cb(new Error('只支持 HTML 文件'));
    }
  },
});

/**
 * 上传壁纸文件
 * POST /api/wallpapers/upload
 */
router.post(
  '/upload',
  upload.single('file'),
  async (req: Request, res: Response) => {
    try {
      if (!req.file) {
        return res.status(400).json({
          code: 'NO_FILE',
          message: '未上传文件',
        });
      }

      const { title, description, tags } = req.body;
      if (!title) {
        return res.status(400).json({
          code: 'MISSING_TITLE',
          message: '缺少标题',
        });
      }

      // 生成唯一文件名
      const fileName = `wallpapers/${Date.now()}_${req.file.originalname}`;

      // 上传到 MinIO
      await minioClient.putObject(
        BUCKET_NAME,
        fileName,
        req.file.buffer,
        req.file.size,
        { 'Content-Type': 'text/html' }
      );

      // 获取文件 URL
      const fileUrl = getFileUrl(fileName);

      // 保存到数据库
      const wallpaper = await prisma.wallpaper.create({
        data: {
          title,
          description: description || null,
          fileUrl,
          fileKey: fileName,
          fileSize: req.file.size,
          userId: req.user?.userId || null, // 允许匿名上传
          tags: tags ? JSON.parse(tags) : [],
          isPublic: true,
        },
      });

      // 清除缓存
      await redis.del('wallpapers:list:*');

      res.json({
        code: 'SUCCESS',
        data: {
          id: wallpaper.id,
          title: wallpaper.title,
          fileUrl,
        },
      });
    } catch (error) {
      console.error('Upload error:', error);
      res.status(500).json({
        code: 'INTERNAL_ERROR',
        message: '上传失败',
      });
    }
  }
);

/**
 * 获取壁纸列表
 * GET /api/wallpapers?page=1&limit=20&sort=latest
 */
router.get('/', async (req: Request, res: Response) => {
  try {
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 20;
    const sort = (req.query.sort as string) || 'latest';
    const offset = (page - 1) * limit;

    // 尝试从缓存读取
    const cacheKey = `wallpapers:list:${page}:${limit}:${sort}`;
    const cached = await redis.get(cacheKey);
    if (cached) {
      return res.json(JSON.parse(cached));
    }

    // 排序选项
    const orderBy: any = {};
    switch (sort) {
      case 'latest':
        orderBy.createdAt = 'desc';
        break;
      case 'popular':
        orderBy.downloadCount = 'desc';
        break;
      // rating 排名暂不支持
    }

    // 查询壁纸列表
    const [wallpapers, total] = await Promise.all([
      prisma.wallpaper.findMany({
        where: { isPublished: true, isApproved: true },
        orderBy,
        skip: offset,
        take: limit,
        include: {
          author: {
            select: { id: true, nickname: true, avatarUrl: true },
          },
        },
      }),
      prisma.wallpaper.count({ where: { isPublished: true, isApproved: true } }),
    ]);

    const result = {
      code: 'SUCCESS',
      data: {
        wallpapers,
        pagination: {
          page,
          limit,
          total,
          totalPages: Math.ceil(total / limit),
        },
      },
    };

    // 缓存 5 分钟
    await redis.setEx(cacheKey, 300, JSON.stringify(result));

    res.json(result);
  } catch (error) {
    console.error('Get wallpapers error:', error);
    res.status(500).json({
      code: 'INTERNAL_ERROR',
      message: '获取壁纸列表失败',
    });
  }
});

/**
 * 获取壁纸详情
 * GET /api/wallpapers/:id
 */
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    const wallpaper = await prisma.wallpaper.findUnique({
      where: { id },
      include: {
        author: {
          select: { id: true, nickname: true, avatarUrl: true },
        },
      },
    });

    if (!wallpaper || !wallpaper.isPublished) {
      return res.status(404).json({
        code: 'WALLPAPER_NOT_FOUND',
        message: '壁纸不存在',
      });
    }

    res.json({
      code: 'SUCCESS',
      data: wallpaper,
    });
  } catch (error) {
    console.error('Get wallpaper detail error:', error);
    res.status(500).json({
      code: 'INTERNAL_ERROR',
      message: '获取壁纸详情失败',
    });
  }
});

/**
 * 增加下载计数
 * POST /api/wallpapers/:id/download
 */
router.post('/:id/download', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    await prisma.wallpaper.update({
      where: { id },
      data: { downloadCount: { increment: 1 } },
    });

    // 清除所有壁纸列表缓存
    const keys = await redis.keys('wallpapers:list:*');
    if (keys.length > 0) {
      await redis.del(keys);
    }

    res.json({
      code: 'SUCCESS',
      message: '下载计数已更新',
    });
  } catch (error) {
    console.error('Increment download count error:', error);
    res.status(500).json({
      code: 'INTERNAL_ERROR',
      message: '更新失败',
    });
  }
});

export default router;
