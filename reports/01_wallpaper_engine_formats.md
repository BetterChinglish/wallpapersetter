# Wallpaper Engine 壁纸格式完整报告

> 报告日期：2026-06-15  
> 对标产品：Wallpaper Engine（Steam 平台）  
> 适用范围：Wallpaper Setter 项目格式设计参考

---

## 一、概述

Wallpaper Engine 是 Windows 平台最主流的动态壁纸软件，支持多种壁纸格式。 understanding these formats is critical for defining the scope of Wallpaper Setter.

---

## 二、Wallpaper Engine 支持的壁纸格式

### 2.1 场景壁纸（Scene Wallpapers）

| 属性 | 说明 |
|------|------|
| **技术基础** | Wallpaper Engine 内置 3D 场景编辑器，基于 DirectX 渲染 |
| **文件格式** | WE 专有格式（`.pkg` 封装，内部为场景描述文件） |
| **创建工具** | Wallpaper Engine 内置 Scene Editor |
| **特点** | 支持粒子效果、光照、音频响应、鼠标交互 |
| **对标难度** | ⭐⭐⭐⭐⭐ 极高，需要自研 3D 引擎 |

**是否建议对标**：❌ MVP 不支持。需要完整的 3D 渲染引擎，开发成本极高。

---

### 2.2 网页壁纸（Web Wallpapers）

| 属性 | 说明 |
|------|------|
| **技术基础** | HTML5 + CSS + JavaScript（WebKit 渲染） |
| **文件格式** | `.html` 或 URL 链接 |
| **创建工具** | 任意网页编辑器 |
| **特点** | 支持 WebGL 3D（Three.js/Babylon.js）、音频 API、鼠标交互 |
| **资源占用** | 中等，取决于网页复杂度 |
| **对标难度** | ⭐⭐ 低，WKWebView 原生支持 |

**是否建议对标**：✅ **核心支持格式**。WKWebView 原生支持，WebGL 内容自动可用。

---

### 2.3 视频壁纸（Video Wallpapers）

| 属性 | 说明 |
|------|------|
| **技术基础** | 预渲染视频文件， direct 播放 |
| **文件格式** | `.mp4`（H.264/H.265）、`.webm` |
| **创建工具** | 任意视频制作软件（AE、Blender 等） |
| **特点** | 最简单，资源占用低，无交互性 |
| **音频** | 支持，可配置静音 |
| **对标难度** | ⭐ 极低，AVPlayer 原生支持 |

**是否建议对标**：✅ **MVP 核心格式**。本地视频播放，技术成熟。

---

### 2.4 应用程序壁纸（Application Wallpapers）

| 属性 | 说明 |
|------|------|
| **技术基础** | 基于 Windows 应用程序窗口作为壁纸 |
| **特点** | 将任意 Windows 应用窗口"贴"在桌面上 |
| **对标难度** | ⭐⭐⭐⭐ 高，macOS 无直接等价技术 |

**是否建议对标**：❌ MVP 不支持。

---

## 三、格式支持对比总结

| 格式 | WE 支持 | Wallpaper Setter MVP | 技术方案 |
|------|---------|----------------------|---------|
| 场景壁纸（3D） | ✅ | ❌ | 需自研 3D 引擎，跳过 |
| 网页壁纸（HTML/WebGL） | ✅ | ✅ | WKWebView 渲染 |
| 视频壁纸（MP4） | ✅ | ✅（本地） | AVPlayerLayer 渲染 |
| 应用程序壁纸 | ✅ | ❌ | macOS 无直接等价方案 |

---

## 四、Wallpaper Setter 格式设计建议

### MVP 阶段
1. **本地视频壁纸**：MP4/MOV，使用 AVPlayer 播放
2. **本地网页壁纸**：HTML/CSS/JS，使用 WKWebView 渲染
3. **社区网页壁纸**：用户上传 HTML 文件，服务端存储，客户端下载后 WKWebView 加载

### 后续扩展
1. **WebGL 3D 壁纸**：通过网页壁纸自然支持（Three.js 等），无需额外开发
2. **视频壁纸社区**：考虑引用模式（存 URL），避免存储成本
3. **实时 3D 场景**：评估 Metal 渲染引擎可行性（高成本）

---

## 五、参考链接

- [Wallpaper Engine 官方设计文档](https://docs.wallpaperengine.io/)
- [Wallpaper Engine 设计文档中文版](https://taiyuuki.github.io/wallpaper-engine-docs/zh/)
