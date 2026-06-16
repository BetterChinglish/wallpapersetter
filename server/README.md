# Wallpaper Setter - 后端服务

macOS 动态壁纸社区平台的后端服务，基于 Node.js + TypeScript + Prisma + PostgreSQL + Redis + MinIO。

## 📦 技术栈

- **运行时**: Node.js 18+
- **语言**: TypeScript 5+
- **框架**: Express.js
- **ORM**: Prisma
- **数据库**: PostgreSQL 14+
- **缓存**: Redis 7+
- **存储**: MinIO (S3 兼容)
- **认证**: JWT + 微信开放平台

## 🚀 快速开始

### 1. 启动依赖服务

```bash
# 启动 Redis（使用 Docker Compose）
cd E:\workplace\wallpapersetter\server
docker-compose up -d redis

# 确认 PostgreSQL 已启动（本地 5432 端口，账号/密码: root/root）
# 确认 MinIO 已启动（本地 9000/9001 端口，账号: myadmin/myadminpwd）
```

### 2. 安装依赖

```bash
cd E:\workplace\wallpapersetter\server
npm install
```

### 3. 配置环境变量

```bash
# .env 文件已创建，核对以下配置：
# - DATABASE_URL: PostgreSQL 连接串
# - REDIS_URL: Redis 连接串
# - MINIO_*: MinIO 配置
# - JWT_SECRET: 随意设置一个复杂字符串
# - WECHAT_APPID / WECHAT_SECRET: 申请微信开放平台后填入
```

### 4. 初始化数据库

```bash
# 创建数据库
createdb -h localhost -p 5432 -U root wallpaper_setter

# 运行 Prisma 迁移
npx prisma migrate dev --name init

# 生成 Prisma Client
npx prisma generate
```

### 5. 启动开发服务器

```bash
npm run dev
```

服务将在 `http://localhost:3000` 启动。

## 📁 项目结构

```
server/
├── src/
│   ├── controllers/      # 控制器（业务逻辑）
│   ├── middleware/        # 中间件（认证、日志等）
│   ├── routes/            # 路由定义
│   ├── services/          # 业务服务层
│   ├── utils/             # 工具函数（Prisma、Redis、MinIO）
│   ├── types/             # TypeScript 类型定义
│   └── index.ts          # 入口文件
├── prisma/
│   ├── schema.prisma     # 数据模型定义
│   └── migrations/        # 数据库迁移文件
├── uploads/               # 本地上传临时目录
├── .env                   # 环境变量（不提交）
├── .env.example           # 环境变量示例
├── docker-compose.yml     # Docker 服务定义
├── package.json
└── tsconfig.json
```

## 🔧 常用命令

```bash
# 开发模式（自动重启）
npm run dev

# 编译 TypeScript
npm run build

# 生产模式
npm start

# Prisma Studio（数据库可视化）
npm run prisma:studio

# 创建新的数据库迁移
npx prisma migrate dev --name <migration_name>

# 重置数据库
npx prisma migrate reset
```

## 🌐 API 端点

### 认证相关

- `GET /api/auth/wechat/qrcode` — 生成微信登录二维码
- `GET /api/auth/wechat/poll?sceneId=xxx` — 轮询登录状态
- `GET /api/auth/wechat/callback` — 微信回调（生产环境）
- `POST /api/auth/logout` — 退出登录

### 壁纸相关

- `POST /api/wallpapers/upload` — 上传壁纸文件
- `GET /api/wallpapers?page=1&limit=20&sort=latest` — 获取壁纸列表
- `GET /api/wallpapers/:id` — 获取壁纸详情
- `POST /api/wallpapers/:id/download` — 增加下载计数

### 系统相关

- `GET /health` — 健康检查

## 📝 数据库模型

详见 `prisma/schema.prisma`，核心模型：

- **User** — 用户（微信 OpenID 登录）
- **Wallpaper** — 壁纸（标题、文件 URL、标签等）
- **UserInteraction** — 用户交互（点赞、收藏、评论）

## 🔒 环境变量说明

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `DATABASE_URL` | PostgreSQL 连接串 | `postgresql://root:root@localhost:5432/wallpaper_setter` |
| `REDIS_URL` | Redis 连接串 | `redis://:root@localhost:6379` |
| `MINIO_ENDPOINT` | MinIO 服务地址 | `localhost` |
| `MINIO_PORT` | MinIO 端口 | `9000` |
| `MINIO_ACCESS_KEY` | MinIO 访问密钥 | `myadmin` |
| `MINIO_SECRET_KEY` | MinIO 密钥 | `myadminpwd` |
| `JWT_SECRET` | JWT 签名密钥 | - |
| `WECHAT_APPID` | 微信开放平台 AppID | - |
| `WECHAT_SECRET` | 微信开放平台 Secret | - |

## 🐛 故障排查

### Redis 连接失败

```bash
# 检查 Redis 是否运行
docker ps | findstr redis

# 手动启动 Redis
docker run -d --name wallpaper-redis -p 6379:6379 redis:7-alpine redis-server --appendonly yes --requirepass root
```

### Prisma 迁移失败

```bash
# 重置数据库（会丢失数据）
npx prisma migrate reset

# 查看数据库状态
npx prisma db pull
```

### MinIO 连接失败

确认 MinIO 已在 Docker 中运行，且 bucket `wallpaper-setter` 已创建：

```bash
# 访问 MinIO 控制台
# http://localhost:9001
# 账号: myadmin / 密码: myadminpwd
```

## 📄 许可证

MIT

---

**搭建时间**: 2026-06-16
