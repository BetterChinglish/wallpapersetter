# Wallpaper Setter — Docker Stack

和 dify 一样的体验：一条命令启动 PostgreSQL / Redis / MinIO / 后端 API 全部依赖。

> **📍 你的角色：** 这是 `wallpapersetter/docker/README.md`。
> 所有命令都在 `docker/` 目录下执行（路径都以它为基准）。

---

## 目录

- [🚀 快速开始（TL;DR）](#-快速开始tldr)
- [📋 启动前置条件](#-启动前置条件)
- [🔧 详细启动流程（每步详解）](#-详细启动流程每步详解)
- [🌐 启动后访问入口](#-启动后访问入口)
- [🛠 开发模式（热重载）](#-开发模式热重载)
- [📊 常用命令速查](#-常用命令速查)
- [🗂 数据落盘位置](#-数据落盘位置)
- [🏗 架构总览](#-架构总览)
- [🧰 镜像说明](#-镜像说明)
- [❓ 排错指南](#-排错指南)
- [🧹 清理与重置](#-清理与重置)

---

## 🚀 快速开始（TL;DR）

```bash
# 在项目根目录
mkdir -p ../dockerCache/{postgresqlCache,redisCache,minioCache}

cd docker
cp .env.example .env
docker compose --profile prod up -d --build
```

等 30~60 秒后访问 http://localhost:3000/health，应返回 `{"status":"ok"}`。

详细流程见下文。

---

## 📋 启动前置条件

| 工具 | 版本 | 用途 | 检查命令 |
|------|------|------|----------|
| Docker Desktop | 4.x+ | 跑容器 | `docker --version` |
| Docker Compose | v2.x（已内置于 Docker Desktop） | 编排服务 | `docker compose version` |
| 空闲端口 | 3000 / 5432 / 6379 / 9000 / 9001 | 各服务监听 | `lsof -i:3000` |
| 磁盘空间 | ≥ 5 GB | 镜像 + 数据 | `df -h` |

**macOS 用户：** 第一次启动 Docker Desktop 需要在菜单栏点 "Open Docker Desktop" 等鲸鱼图标稳定。

**Windows 用户：** 推荐用 WSL2 后端；如果是 Hyper-V 后端，bind mount 路径要走 `\\wsl$\...` 或在 Docker Desktop 设置里配置好共享盘符。

---

## 🔧 详细启动流程（每步详解）

### Step 1 — 准备数据卷目录

```bash
# 还在项目根目录（wallpapersetter/）
mkdir -p dockerCache/{postgresqlCache,redisCache,minioCache}
```

> **为什么需要？** 我们的 compose 把数据通过 bind mount 落到 `dockerCache/`（按你之前的要求）。
> 提前 `mkdir` 是为了把目录所属用户设对 —— **postgres 容器以 uid 999 启动**，
> 如果目录属主是你当前用户（uid 1000 左右），容器会因为写不进去报错。
> 先建好、再启动，docker 会把目录交给容器管理。

```bash
# 验证
ls -la dockerCache/
# 应该看到三个空目录
```

### Step 2 — 进入 docker 目录并复制环境变量模板

```bash
cd docker
cp .env.example .env
```

> **为什么用 cp 而不是直接编辑 `.env.example`？**
> `.env.example` 是入 git 的模板，`.env` 是你本地的真值，不入 git。
> 万一改坏了，删掉 `.env` 重新 `cp` 一份就行。

```bash
# （可选）查看默认值是否合用
cat .env
```

> **生产环境必改：** `JWT_SECRET` 这一项必须改成自己的随机串（至少 32 字符）。
> 其他默认值（root/myadmin 等）仅供本地开发。

### Step 3 — 拉起所有服务（首次含构建）

```bash
docker compose --profile prod up -d --build
```

这条命令背后会按顺序做这些事：

| 阶段 | 发生的事情 | 你会看到 |
|------|----------|---------|
| ① 构建 server 镜像 | 拉 node:22-alpine → 装依赖 → 编译 TS → 生成最终镜像 `wallpaper-setter-server:dev` | 几屏 npm install 和 tsc 输出 |
| ② 启动基础设施 | 拉 `postgres:16-alpine` / `redis:7-alpine` / `minio/minio:latest` / `minio/mc:latest` | 第一次会下载几百 MB 镜像 |
| ③ 启动 postgres | 容器起来，初始化 `wallpaper_setter` 库 | 几秒钟内打印 `database system is ready to accept connections` |
| ④ 启动 redis | 容器起来，ping 通 | 几乎瞬间 |
| ⑤ 启动 minio | 容器起来，监听 9000/9001 | 约 3-5 秒 |
| ⑥ 启动 minio-init（一次性） | 等待 minio 健康 → 用 `mc` 客户端建 `wallpapers` 桶 → 退出 | 日志里出现 `MinIO bucket ready: wallpapers` |
| ⑦ 启动 server | entrypoint 脚本：等 db → prisma generate → migrate deploy / db push → `node dist/index.js` | 日志里出现 `🚀 Server is running on http://localhost:3000` |

> **参数解释：**
> - `--profile prod`：只起 prod profile 里的服务（`server`，不包含 `server-dev`）
> - `up`：拉起
> - `-d`：后台运行（detached）
> - `--build`：先构建 server 镜像。**首次必须带**，之后改了 Dockerfile 才需要带

### Step 4 — 验证启动成功

#### 4.1 看容器状态

```bash
docker compose --profile prod ps
```

预期输出（CONTAINER 一列、STATUS 一列）：

```
NAME             STATUS              PORTS
wp-postgres      Up (healthy)        0.0.0.0:5432->5432/tcp
wp-redis         Up (healthy)        0.0.0.0:6379->6379/tcp
wp-minio         Up (healthy)        0.0.0.0:9000-9001->9000-9001/tcp
wp-minio-init    Exited (0)          # 一次性，正常
wp-server        Up (healthy)        0.0.0.0:3000->3000/tcp
```

> **STATUS 列要看到 `(healthy)`。** 如果是 `Up X seconds (health: starting)`，多等几秒再查一次。
> 如果是 `unhealthy`，跳到下面 [排错指南](#-排错指南)。

#### 4.2 测后端健康检查

```bash
curl http://localhost:3000/health
```

预期返回：

```json
{"status":"ok","timestamp":"2026-06-24T...","uptime":12.345}
```

#### 4.3 测数据库

```bash
# 进 postgres 容器内部
docker compose --profile prod exec postgres psql -U root -d wallpaper_setter

# 在 psql 里
\dt
# 应该看到 users / wallpapers / favorites / downloads / likes / sessions 这些表
\q
```

#### 4.4 测 MinIO

浏览器打开 http://localhost:9001，用 `myadmin` / `myadminpwd` 登录，应该能看到 `wallpapers` 桶。

### Step 5 — 启动完成 ✅

到这里后端栈就完全可用了。开始你的开发：
- 改 `server/src/...` 的代码 → prod 模式需要 `docker compose --profile prod up -d --build server` 重新构建
- 改 `server/prisma/schema.prisma` → 同上，重新构建 server 即可（entrypoint 会自动跑 `db push`）
- 想看实时日志：`docker compose --profile prod logs -f server`

---

## 🌐 启动后访问入口

| 服务 | 地址 | 凭据 |
|------|------|------|
| Backend API | http://localhost:3000 | — |
| Health check | http://localhost:3000/health | — |
| PostgreSQL | `localhost:5432` | `root` / `root` / db `wallpaper_setter` |
| Redis | `localhost:6379` | 无密码 |
| MinIO API (S3) | http://localhost:9000 | `myadmin` / `myadminpwd` |
| MinIO Console (Web) | http://localhost:9001 | `myadmin` / `myadminpwd` |

---

## 🛠 开发模式（热重载）

当你需要频繁改代码并立刻看到效果时，用 dev profile：

```bash
# 1. 停掉 prod
cd docker
docker compose --profile prod down

# 2. 起 dev（同样会先构建镜像）
docker compose --profile dev up --build
```

dev 模式区别：
- 后端用 `ts-node-dev`，改了 `server/src/` 或 `server/prisma/` 内的文件**自动重载**，不用重建镜像
- `server/src/` 和 `server/prisma/` 走 bind mount 挂进容器，文件直接共享
- 跑在 `wp-server-dev` 容器里（不与 prod 容器冲突）

**dev 模式特殊工作流：**
- 改了 schema：`ts-node-dev` 会自己跑 `prisma generate`；你需要在另一个终端跑 `npx prisma db push` 同步 db（或者改 entrypoint 也加这一行，下次重启时自动）
- 改了 Dockerfile：必须 `docker compose --profile dev up --build server-dev`

切回 prod：`docker compose --profile dev down && docker compose --profile prod up -d --build`

---

## 📊 常用命令速查

```bash
# === 状态 ===
docker compose --profile prod ps          # 看所有 prod 服务状态
docker compose --profile dev ps           # 看 dev 服务

# === 日志 ===
docker compose --profile prod logs -f server       # 实时跟 server 日志
docker compose --profile prod logs --tail 100      # 看最近 100 行
docker compose --profile prod logs postgres         # 看 postgres 日志

# === 调试 ===
docker compose --profile prod exec server sh                 # 进 server 容器
docker compose --profile prod exec postgres psql -U root      # 直连 db
docker compose --profile prod exec redis redis-cli            # 直连 redis

# === 启停 ===
docker compose --profile prod stop           # 停容器（保留数据）
docker compose --profile prod start          # 启已存在的容器
docker compose --profile prod restart server # 重启单个服务
docker compose --profile prod down           # 删容器（保留数据卷）
```

---

## 🗂 数据落盘位置

所有持久化数据都在项目根的 `wallpapersetter/dockerCache/` 下，`.gitignore` 已经忽略它：

```
dockerCache/
├── postgresqlCache/   # Postgres 数据文件（PGDATA）
├── redisCache/        # Redis AOF 持久化文件
└── minioCache/        # MinIO 对象存储文件
```

**迁移整个项目：** 把 `dockerCache/` 拷走就行，重新 `docker compose up -d` 就能复现完整状态。

**为什么是 bind mount 而不是 docker volume？** 按你最初的要求"数据保存在工作目录的 cache 下"。缺点是不如 named volume 跨平台稳，优点是你能直接 `ls` / `du` 看大小，也方便手动备份。

---

## 🏗 架构总览

```
┌─────────────────────────────────────────────────────────────┐
│                    docker-compose network                    │
│                                                              │
│   ┌──────────┐    ┌──────────┐    ┌──────────┐             │
│   │ postgres │◀───│  server  │───▶│  redis   │             │
│   │  :5432   │    │  :3000   │    │  :6379   │             │
│   └────▲─────┘    └────┬─────┘    └──────────┘             │
│        │               │                                    │
│        │   ┌───────────▼──────────┐                        │
│        │   │  minio               │                        │
│        │   │  :9000 (api)         │                        │
│        │   │  :9001 (console)     │                        │
│        │   └───────────▲──────────┘                        │
│        │               │                                    │
│        │         ┌─────┴──────┐                             │
│        │         │ minio-init │  (one-shot, exits after     │
│        └─────────┤  builds    │   bucket is created)       │
│       (waits for │  bucket    │                             │
│        healthy)  └────────────┘                             │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                            ▲
                            │  宿主机 localhost
                            │  (port mapping)
                            ▼
        Browser / psql / redis-cli / mc 客户端
```

**启动顺序（健康检查驱动）：**
1. `postgres` 启动 → `pg_isready` 通过
2. `redis` 启动 → `redis-cli ping` 通过
3. `minio` 启动 → `/minio/health/live` 返回 200
4. `minio-init` 启动（依赖 3 健康） → 建好桶后退出 0
5. `server` 启动（依赖 1、2、4） → entrypoint 跑完迁移 → `/health` 返回 200

**网络：** 所有服务在 compose 创建的默认 bridge 网络上，**互相用 service 名访问**（`postgres` / `redis` / `minio`）。**宿主机用 `localhost` + 端口**。

---

## 🧰 镜像说明

dev / prod 模式都通过 `server/Dockerfile` 本地构建（**不依赖 Docker Hub**）。

| Target | 用于 | 启动命令 |
|--------|------|---------|
| `prod` | prod profile | 编译 TS → `node dist/index.js` |
| `dev`  | dev profile  | `ts-node-dev` + bind mount 源码 |
| `base` | 内部 | 装 openssl + libpq |
| `deps` | 内部 | `npm ci` + `prisma generate` |
| `builder` | 内部 | 跑 `tsc` |

**如果以后要发布到 Docker Hub 给别人用：**

```bash
# 本地构建并推送
docker buildx build --platform linux/amd64,linux/arm64 \
  -t your-dockerhub-user/wallpaper-setter-server:1.0.0 \
  --push ../server

# 然后在 docker-compose.yml 里改一行：
#   image: wallpaper-setter-server:dev
#   ↓
#   image: your-dockerhub-user/wallpaper-setter-server:1.0.0
# 并删掉 build: 段
```

别人 clone 项目后，直接 `docker compose up -d` 不需要本地构建。

---

## ❓ 排错指南

### 1. "port is already allocated"

说明 3000/5432/6379/9000/9001 之一被本机其他进程占着。

```bash
# 找出谁占着
lsof -i:3000 -i:5432 -i:6379 -i:9000 -i:9001

# 杀掉（确认是 docker 残留或本地服务）
lsof -ti:3000,5432,6379,9000,9001 | xargs -r kill -9

# 如果是 brew 装的本地服务
brew services stop postgresql redis minio/stable/minio 2>/dev/null
```

### 2. postgres 容器一直重启 / 报 "permission denied"

`dockerCache/postgresqlCache/` 目录的所属用户不对。

```bash
# 删掉旧目录让 docker 重建（会丢数据，请先确认你不需要）
cd ..
sudo rm -rf dockerCache/postgresqlCache
mkdir dockerCache/postgresqlCache
cd docker
docker compose --profile prod up -d postgres
```

### 3. server 起来后马上退出，日志里有 "Can't reach database server"

正常，server entrypoint 里有等 db 的逻辑（最多 60 次 × 2 秒）。如果一直起不来：

```bash
docker compose --profile prod logs postgres
# 看是不是 postgres 健康检查没通过
```

### 4. 改了 `server/prisma/schema.prisma` 但 db 没同步

prod 模式：必须重建 server 镜像，因为 `prisma generate` 在构建阶段跑：
```bash
docker compose --profile prod up -d --build server
```

dev 模式：`ts-node-dev` 会自动重跑 `prisma generate`，但**不会自动 push** 到 db，需要在容器内手动：
```bash
docker compose --profile dev exec server-dev npx prisma db push
```

### 5. MinIO 控制台登录后看不到 `wallpapers` 桶

`minio-init` 容器失败或被跳过了：

```bash
# 重新跑一次建桶
docker compose --profile prod run --rm minio-init

# 看具体报错
docker compose --profile prod logs minio-init
```

### 6. 想看 server 实时打印的 SQL / 错误

```bash
docker compose --profile prod logs -f server
```

---

## 🧹 清理与重置

| 想要 | 命令 |
|------|------|
| 停服务（保留数据，下次起来还在） | `docker compose --profile prod stop` |
| 删容器（保留数据卷） | `docker compose --profile prod down` |
| 删容器 + 删 server 镜像 | `docker compose --profile prod down --rmi local` |
| **完全重置（数据也没了）** | `cd .. && rm -rf dockerCache/ && cd docker && docker compose --profile prod down --rmi local` |

> ⚠️ **完全重置不可逆。** 执行前确认 `dockerCache/` 没有你需要保留的数据，或者已经备份过。
