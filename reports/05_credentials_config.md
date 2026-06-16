# Wallpaper Setter — 环境配置与凭据汇总

> **⚠️ 安全提醒：** 此文档包含敏感凭据，请勿提交到公开代码仓库。  
> 更新时间: 2026-06-16

---

## 1️⃣ PostgreSQL 数据库

| 项目 | 值 |
|------|-----|
| 主机 | `localhost` |
| 端口 | `5432` |
| 数据库名 | `wallpaper_setter` |
| 用户 | `postgres` |
| 密码 | `root` |
| 连接字符串 | `postgresql://postgres:root@localhost:5432/wallpaper_setter?schema=public` |

**状态：** ✅ 运行中（本地安装）

---

## 2️⃣ Redis 缓存

| 项目 | 值 |
|------|-----|
| 主机 | `localhost` |
| 端口 | `6379` |
| 密码 | *无密码（本地环境）* |
| 持久化路径 | `E:\workplace\redis\data` |

**状态：** ✅ 运行中（本地安装）  
**Docker 备用启动命令：**
```bash
docker run -d --name wallpaper-redis -p 6379:6379 redis:7-alpine redis-server --appendonly yes --requirepass myredispwd
```

---

## 3️⃣ MinIO 对象存储

| 项目 | 值 |
|------|-----|
| API 端点 | `localhost:9000` |
| 控制台地址 | `http://localhost:9001` |
| Access Key | `myadmin` |
| Secret Key | `myadminpwd` |
| Bucket | `wallpapers` |
| SSL | ❌ 未启用 |
| 数据路径 | `E:\workplace\minio\data` |

**状态：** ✅ 运行中（Docker 部署）  
**注意：** 需要在控制台手动创建 `wallpapers` Bucket。

---

## 4️⃣ JWT 安全配置

| 项目 | 值 |
|------|-----|
| 密钥 | `your-super-secret-jwt-key-change-in-production` |
| 过期时间 | `7d` |

> **生产环境必须修改密钥！**

---

## 5️⃣ 微信登录（待配置）

| 项目 | 当前值 |
|------|--------|
| App ID | *未配置* |
| App Secret | *未配置* |
| 回调 URL | `http://localhost:3000/api/auth/wechat/callback` |

---

## 6️⃣ 后端服务

| 项目 | 值 |
|------|-----|
| 端口 | `3000` |
| 环境 | `development` |
| 健康检查 | `http://localhost:3000/health` |

**启动命令：**
```bash
cd E:\workplace\wallpapersetter\server
npm run dev
```

---

## 7️⃣ 项目结构

```
E:\workplace\wallpapersetter\
├── reports/                          # 项目文档
│   ├── 01_wallpaper_engine_formats.md
│   ├── 02_macos_feasibility_analysis.md
│   ├── 03_tech_stack_report.md
│   ├── 04_api_documentation.md
│   └── ...
├── server/                           # 后端项目
│   ├── prisma/
│   │   └── schema.prisma             # 数据模型
│   ├── prisma.config.ts              # Prisma 7 配置
│   ├── src/
│   │   ├── index.ts                  # 入口 + Express 配置
│   │   ├── routes/
│   │   │   ├── auth.ts               # 微信登录
│   │   │   └── wallpapers.ts         # 壁纸 CRUD
│   │   ├── middleware/
│   │   │   └── auth.ts               # JWT 认证
│   │   └── utils/
│   │       ├── prisma.ts             # Prisma Client
│   │       ├── redis.ts              # Redis 连接
│   │       └── minio.ts              # MinIO 存储
│   └── .env                          # 环境变量
└── ... （后续 macOS 客户端、前端等）
```

---

## 8️⃣ 技术栈总览

| 组件 | 技术 | 说明 |
|------|------|------|
| 后端语言 | TypeScript 6.x | 强类型 JavaScript |
| Web 框架 | Express 5.x | HTTP 服务 |
| ORM | Prisma 7.x | 数据库操作 |
| 数据库 | PostgreSQL 16+ | 主数据库 |
| 缓存 | Redis 6.x | 缓存 + 会话 |
| 对象存储 | MinIO | 文件存储（兼容 S3）|
| 认证 | JWT + 微信扫码 | 用户认证 |
| 客户端（规划中）| Swift + SwiftUI | macOS 原生应用 |

---

## 9️⃣ 端口占用清单

| 端口 | 服务 | 说明 |
|------|------|------|
| 3000 | Wallpaper Setter API | 后端服务 |
| 5432 | PostgreSQL | 主数据库 |
| 6379 | Redis | 缓存服务 |
| 9000 | MinIO API | 对象存储 API |
| 9001 | MinIO Console | 对象存储管理后台 |

---

## 🔟 开发备注

- Redis 本地运行时**未设置密码**（开发环境安全风险低）
- MinIO 通过 Docker 部署（`docker ps` 查看状态）
- PostgreSQL 通过 Windows 本地安装
- 所有依赖使用 `npm install <包名>` 自动获取最新版本
- Prisma 7 需要 `@prisma/adapter-pg` + `pg` 驱动包
