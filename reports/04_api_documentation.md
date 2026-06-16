# Wallpaper Setter — API 接口文档

> 版本: v1.0  
> 基础地址: `http://localhost:3000`  
> 编码: UTF-8  
> 内容类型: `application/json`

---

## 1️⃣ 系统状态

### `GET /health`
健康检查端点，用于监控服务运行状态。

**响应：**
```json
{
  "status": "ok",
  "timestamp": "2026-06-15T17:29:10.292Z",
  "uptime": 13.54
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| status | string | 服务状态 (`ok`) |
| timestamp | string | ISO 8601 时间戳 |
| uptime | number | 服务已运行秒数 |

---

## 2️⃣ 壁纸相关

### `GET /api/wallpapers`
获取壁纸列表（支持分页、排序）。

**参数：**

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| page | number | 1 | 页码 |
| limit | number | 20 | 每页数量 |
| sort | string | `latest` | 排序方式：`latest`（最新）、`popular`（最热） |

**响应：**
```json
{
  "code": "SUCCESS",
  "data": {
    "wallpapers": [...],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 0,
      "totalPages": 0
    }
  }
}
```

**缓存说明：** 列表数据缓存 5 分钟（Redis key: `wallpapers:list:{page}:{limit}:{sort}`）。

---

### `GET /api/wallpapers/:id`
获取单个壁纸详情。

**参数：**

| 参数 | 类型 | 说明 |
|------|------|------|
| id | string | 壁纸 UUID（路径参数）|

**响应：**
```json
{
  "code": "SUCCESS",
  "data": {
    "id": "uuid",
    "title": "壁纸标题",
    "description": "描述",
    "type": "VIDEO | WEB",
    "contentUrl": "文件URL",
    "thumbnailUrl": "缩略图URL",
    "fileSize": 1024,
    "viewCount": 0,
    "downloadCount": 0,
    "likeCount": 0,
    "author": {
      "id": "uuid",
      "nickname": "昵称",
      "avatarUrl": "头像URL"
    },
    "createdAt": "2026-06-15T00:00:00.000Z"
  }
}
```

**错误：**
| 状态码 | code | 说明 |
|--------|------|------|
| 404 | WALLPAPER_NOT_FOUND | 壁纸不存在或未发布 |

---

### `POST /api/wallpapers/upload`
上传壁纸文件（仅 HTML 格式）。

**请求头：**
```
Content-Type: multipart/form-data
```

**表单字段：**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| file | file | ✅ | HTML 文件（最大 10MB）|
| title | string | ✅ | 壁纸标题（最长 128 字符）|
| description | string | ❌ | 壁纸描述 |

**文件限制：**
- 仅允许 `text/html` 或 `.html` 后缀
- 最大 10MB

**响应：**
```json
{
  "code": "SUCCESS",
  "data": {
    "id": "壁纸UUID",
    "title": "壁纸标题",
    "fileUrl": "文件访问URL"
  }
}
```

**存储流程：** 文件 → MinIO 对象存储 → 数据库记录

---

### `POST /api/wallpapers/:id/download`
增加壁纸下载计数。

**参数：**

| 参数 | 类型 | 说明 |
|------|------|------|
| id | string | 壁纸 UUID（路径参数）|

**响应：**
```json
{
  "code": "SUCCESS",
  "message": "下载计数已更新"
}
```

---

## 3️⃣ 微信登录

### `GET /api/auth/wechat/qrcode`
生成微信登录二维码。

**响应：**
```json
{
  "code": "SUCCESS",
  "data": {
    "sceneId": "wallpaper_xxx",
    "qrcodeUrl": "https://open.weixin.qq.com/...",
    "expiresIn": 300
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| sceneId | string | 场景值（用于轮询）|
| qrcodeUrl | string | 微信授权 URL |
| expiresIn | number | 过期时间（秒）|

**Redis 存储的临时数据：**
```
Key: wechat_auth:{sceneId}
Value: {"status":"pending","createdAt":timestamp}
TTL: 300 秒
```

---

### `GET /api/auth/wechat/poll?sceneId=xxx`
轮询微信登录状态。

**参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| sceneId | string | ✅ | 二维码场景值 |

**响应（等待扫码）：**
```json
{ "code": "PENDING", "message": "等待扫码" }
```

**响应（授权成功）：**
```json
{
  "code": "SUCCESS",
  "data": {
    "token": "jwt.token.here",
    "user": {
      "id": "用户UUID",
      "nickname": "用户昵称",
      "avatarUrl": "头像URL"
    }
  }
}
```

**响应（过期）：**
```json
{ "code": "QRCODE_EXPIRED", "message": "二维码已过期" }
```

---

### `GET /api/auth/wechat/callback?code=xxx&state=xxx`
微信 OAuth 回调端点（接收微信授权码）。

**参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| code | string | ✅ | 微信授权码 |
| state | string | ✅ | 场景值（含 sceneId）|

**说明：** 开发阶段返回模拟成功页面。生产环境需对接微信开放平台 API。

---

### `POST /api/auth/logout`
退出登录（Token 加入黑名单）。

**请求头：**
```
Authorization: Bearer <jwt-token>
```

**响应：**
```json
{
  "code": "SUCCESS",
  "message": "退出成功"
}
```

---

## 4️⃣ 数据模型

### Wallpaper（壁纸）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| title | VARCHAR(128) | 标题 |
| description | TEXT | 描述 |
| type | ENUM | `VIDEL` \| `WEB` |
| contentUrl | String | 文件路径 |
| videoLocal | Boolean | 是否本地视频 |
| thumbnailUrl | String | 缩略图 URL |
| fileSize | Int | 文件大小（字节）|
| authorId | UUID | 作者 ID |
| viewCount | Int | 浏览数 |
| downloadCount | Int | 下载数 |
| likeCount | Int | 点赞数 |
| isPublished | Boolean | 是否发布 |
| isApproved | Boolean | 是否审核通过 |
| createdAt | DateTime | 创建时间 |

### User（用户）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| openid | String | 微信 openid |
| nickname | String | 昵称 |
| avatarUrl | String | 头像 URL |
| role | ENUM | `USER` \| `ADMIN` |
| createdAt | DateTime | 创建时间 |

### Session（会话）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| userId | UUID | 用户 ID |
| token | String | JWT Token |
| expiresAt | DateTime | 过期时间 |

---

## 5️⃣ 通用响应格式

### 成功响应
```json
{ "code": "SUCCESS", "data": { ... } }
```

### 错误响应
| 状态码 | 说明 |
|--------|------|
| 400 | 参数错误 |
| 404 | 资源不存在 |
| 500 | 服务器内部错误 |

```json
{
  "code": "ERROR_CODE",
  "message": "错误描述"
}
```

---

## 6️⃣ 缓存策略

| 缓存内容 | Key 格式 | TTL |
|----------|----------|-----|
| 壁纸列表 | `wallpapers:list:{page}:{limit}:{sort}` | 300s |
| 微信登录状态 | `wechat_auth:{sceneId}` | 300s |
| Token 黑名单 | `token_blacklist:{token}` | 3600s |

---

## 7️⃣ 技术栈

| 组件 | 技术 | 版本 |
|------|------|------|
| 运行时 | Node.js | ≥ 18 |
| 语言 | TypeScript | 6.x |
| Web 框架 | Express | 5.x |
| ORM | Prisma | 7.x |
| 数据库 | PostgreSQL | 16+ |
| 缓存 | Redis | 6.x |
| 对象存储 | MinIO | 最新 |
| 文件上传 | Multer | 2.x |
| 认证 | JWT + 微信扫码 | — |
