# Wallpaper Setter 技术栈选型报告

> 报告日期：2026-06-15  
> 项目：Wallpaper Setter（macOS 动态壁纸软件 + 社区后端）  
> 目标：选定前后端技术栈，支持微信登录，指导 MVP 开发

---

## 一、技术栈总览

```
┌─────────────────────────────────────────────────────┐
│                    Wallpaper Setter                  │
├──────────────────────┬──────────────────────────────┤
│    macOS 客户端       │        后端服务               │
│  (Swift + SwiftUI)   │   (Node.js + TypeScript)     │
├──────────────────────┼──────────────────────────────┤
│  • AVPlayer          │  • Express / Koa             │
│  • WKWebView         │  • PostgreSQL + Redis        │
│  • AppKit            │  • 微信开放平台 SDK           │
│  • Combine           │  • REST API                  │
└──────────────────────┴──────────────────────────────┘
```

---

## 二、客户端技术栈（macOS）

### 2.1 核心技术

| 技术 | 版本/要求 | 用途 | 选型理由 |
|------|----------|------|---------|
| **Swift** | 5.9+ | 主力开发语言 | 苹果原生，性能最佳 |
| **SwiftUI** | macOS 14+ | UI 框架 | 声明式 UI，开发效率高 |
| **AppKit** | macOS 14+ | 底层窗口控制 | 需访问 `NSWindow` 层级 API，SwiftUI 封装不足 |
| **AVFoundation** | 系统框架 | 视频播放 | `AVPlayer` 硬件加速，低资源占用 |
| **WebKit** | 系统框架 | 网页壁纸渲染 | `WKWebView`，原生 WebKit 引擎 |
| **Combine** | 系统框架 | 响应式编程 | 处理异步事件（壁纸切换、网络请求） |
| **CocoaPods / SPM** | - | 依赖管理 | SPM 优先，苹果官方推荐 |

### 2.2 关键依赖库（推荐）

| 库名 | 用途 | 地址 |
|------|------|------|
| `Alamofire` | 网络请求 | SPM 可用 |
| `Kingfisher` | 图片加载/缓存 | SPM 可用 |
| `SwiftyJSON` | JSON 解析 | SPM 可用 |
| `KeychainAccess` | 安全存储 Token | SPM 可用 |

### 2.3 客户端架构建议

```
Wallpaper Setter/
├── Models/          # 数据模型（Wallpaper, User, etc.）
├── Views/           # SwiftUI 视图
├── ViewModels/      # 业务逻辑（Combine）
├── Services/        # 服务层
│   ├── WallpaperEngine/   # 壁纸渲染引擎（视频+网页）
│   ├── CommunityService/  # 社区 API 调用
│   └── AuthService/       # 微信登录
├── Utilities/       # 工具类（权限、多屏幕等）
└── Resources/       # 资源文件
```

---

## 三、后端技术栈

### 3.1 核心技术

| 技术 | 版本 | 用途 | 选型理由 |
|------|------|------|---------|
| **Node.js** | 20 LTS+ | 运行时 | 长期支持版，稳定 |
| **TypeScript** | 5.0+ | 开发语言 | 类型安全，减少运行时错误 |
| **Express / Koa** | Express 4.x | Web 框架 | 生态成熟，微信登录中间件丰富 |
| **PostgreSQL** | 16+ | 主数据库 | 关系完整，JSON 支持好（壁纸元数据灵活） |
| **Redis** | 7+ | 缓存 + Session | 微信登录 Session、热点壁纸缓存 |
| **MinIO / 本地存储** | - | HTML 文件存储 | 社区壁纸 HTML 文件存储（体积小） |
| **Docker** | - | 部署 | 环境一致性 |

### 3.2 项目结构建议

```
wallpaper-setter-backend/
├── src/
│   ├── controllers/    # 路由控制器
│   ├── services/      # 业务逻辑
│   ├── models/        # 数据模型（TypeORM / Prisma）
│   ├── middleware/    # 中间件（鉴权、日志等）
│   ├── routes/        # 路由定义
│   ├── utils/         # 工具函数
│   └── index.ts       # 入口
├── uploads/           # HTML 文件存储目录
├── prisma/            # Prisma Schema（如果用 Prisma）
└── docker-compose.yml # 本地开发环境
```

### 3.3 数据库 Schema 设计（核心表）

```sql
-- 用户表
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wechat_openid VARCHAR(64) UNIQUE NOT NULL,
    nickname VARCHAR(64),
    avatar_url TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 壁纸表
CREATE TABLE wallpapers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(128) NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('video', 'web')),
    -- 视频壁纸：null（本地 only）
    -- 网页壁纸：HTML 文件路径或 URL
    content_url TEXT,
    thumbnail_url TEXT,
    author_id UUID REFERENCES users(id),
    download_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 用户壁纸收藏表
CREATE TABLE user_wallpapers (
    user_id UUID REFERENCES users(id),
    wallpaper_id UUID REFERENCES wallpapers(id),
    PRIMARY KEY (user_id, wallpaper_id)
);
```

---

## 四、微信登录集成方案

### 4.1 登录流程（扫码登录）

```
[macOS 客户端]              [后端服务器]              [微信开放平台]
     │                          │                        │
     │  1. 请求二维码           │                        │
     ├─────────────────────────>│                        │
     │  2. 返回二维码 + scene_id│                        │
     │<─────────────────────────┤                        │
     │  3. 展示二维码           │                        │
     │                          │  4. 请求微信扫码登录   │
     │                          ├───────────────────────>│
     │                          │  5. 返回扫码结果       │
     │                          │<───────────────────────┤
     │  6. 轮询登录状态         │                        │
     ├─────────────────────────>│                        │
     │  7. 返回 Token           │                        │
     │<─────────────────────────┤                        │
     │  8. 存储 Token           │                        │
     │                          │                        │
```

### 4.2 后端实现要点

```typescript
// 1. 获取微信二维码
app.get('/api/auth/wechat/qrcode', async (req, res) => {
  const scene_id = generateSceneId();
  const qrcodeUrl = await getWechatQRCode(scene_id);
  res.json({ qrcodeUrl, scene_id });
});

// 2. 微信回调接口
app.post('/api/auth/wechat/callback', async (req, res) => {
  const { code } = req.body;
  const userInfo = await exchangeCodeForUserInfo(code);
  const token = generateJWT(userInfo.openid);
  res.json({ token });
});

// 3. 客户端轮询登录状态
app.get('/api/auth/wechat/status/:scene_id', async (req, res) => {
  const status = await getLoginStatus(req.params.scene_id);
  res.json(status);
});
```

### 4.3 所需微信开放平台配置

| 配置项 | 说明 |
|--------|------|
| 开放平台账号 | 需企业资质认证（个人无法申请网站应用） |
| 应用类型 | 网站应用（Web） |
| 回调域名 | 你的后端域名（如 `api.wallpapersetter.com`） |
| Scope | `snsapi_login`（扫码登录） |

> ⚠️ **注意**：微信开放平台网站应用需要企业资质。如果是个人的话，考虑：
> - 用邮箱/手机登录替代
> - 或接入微信小程序登录（需要小程序）
> - 或个人开发者账号（限制较多）

---

## 五、社区壁纸上传方案

### 5.1 上传流程

```
客户端                          后端                        存储
  │                              │                            │
  │  1. 选择 HTML 文件           │                            │
  ├─────────────────────────────>│                            │
  │  2. JWT Token 鉴权           │                            │
  │  3. 上传 HTML + 缩略图       │                            │
  ├─────────────────────────────>│                            │
  │                              │  4. 保存 HTML 到本地/MinIO │
  │                              ├───────────────────────────>│
  │                              │  5. 写入数据库             │
  │  6. 返回壁纸 ID              │                            │
  │<─────────────────────────────┤                            │
```

### 5.2 安全考虑

- HTML 文件需做安全扫描（防止 XSS）
- 限制 HTML 文件大小（建议 < 5MB）
- 缩略图建议客户端截图上传，或服务端 Puppeteer 生成
- 社区壁纸需审核机制（MVP 可先人工审核）

---

## 六、API 设计（核心接口）

### 6.1 认证相关

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/auth/wechat/qrcode` | 获取微信登录二维码 |
| GET | `/api/auth/wechat/status/:scene_id` | 轮询登录状态 |
| POST | `/api/auth/wechat/callback` | 微信回调接口 |
| POST | `/api/auth/logout` | 登出 |

### 6.2 壁纸相关

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/wallpapers` | 壁纸列表（分页、筛选） |
| GET | `/api/wallpapers/:id` | 壁纸详情 |
| POST | `/api/wallpapers` | 上传壁纸（需鉴权） |
| GET | `/api/wallpapers/:id/download` | 下载壁纸 HTML |
| POST | `/api/wallpapers/:id/like` | 点赞壁纸 |

---

## 七、部署方案

### 7.1 后端部署

| 方案 | 说明 |
|------|------|
| **云服务器** | 阿里云/腾讯云 ECS，1核2G 起步（MVP 够用） |
| **Docker 部署** | 后端 + PG + Redis 一键启动 |
| **Nginx 反向代理** | SSL 终止、静态文件服务 |
| **CDN** | 缩略图用 CDN 加速（可选） |

### 7.2 成本预估（MVP 阶段）

| 项目 | 月成本 |
|------|--------|
| 云服务器（1核2G） | ~¥30 |
| 域名 + SSL | ~¥10/年 |
| PostgreSQL（自建） | 包含在服务器内 |
| 对象存储（MinIO 自建） | 包含在服务器内 |
| **合计** | **~¥35/月** |

---

## 八、技术风险与应对

| 风险 | 影响 | 应对 |
|------|------|------|
| 微信登录需要企业资质 | 无法接入微信登录 | MVP 先用邮箱登录，或接 Apple ID |
| WKWebView 性能瓶颈 | 复杂网页壁纸卡顿 | 限制网页壁纸复杂度，提供性能提示 |
| 后端单点故障 | 社区功能不可用 | MVP 阶段可接受，后续加热备 |
| HTML 安全问题 | XSS 攻击 | 服务端扫描 + 沙盒隔离（WKWebView 沙盒） |

---

## 九、总结与下一步

### 技术栈确认

| 层级 | 技术选型 | 状态 |
|------|---------|------|
| 客户端 | Swift + SwiftUI + AVPlayer + WKWebView | ✅ 确认 |
| 后端 | Node.js + TypeScript + Express + PG + Redis | ✅ 确认 |
| 登录 | 微信扫码登录（需企业资质） | ⚠️ 待确认资质 |
| 部署 | 云服务器 + Docker + Nginx | ✅ 确认 |

### 下一步行动

1. 确认微信开放平台资质情况
2. 搭建后端基础框架（Express + TS + Prisma）
3. 创建 SwiftUI 客户端项目，实现壁纸渲染引擎原型
4. 设计数据库 Schema，初始化 PG
