# macOS 壁纸软件可行性分析报告

> 报告日期：2026-06-15  
> 分析目标：评估在 macOS 14 Sonoma+ 上开发 Wallpaper Setter 的技术可行性  
> 结论：**可行，推荐实施**

---

## 一、核心结论

| 维度 | 结论 |
|------|------|
| **技术可行性** | ✅ 可行，macOS 提供完整的底层 API |
| **资源占用** | ✅ 可控，原生技术栈占用低 |
| **分发可行性** | ✅ 可行，但 App Store 审核有风险 |
| **开发成本** | ⚠️ 中等，需处理多屏幕、权限等细节 |
| **综合推荐** | ✅ **推荐实施，MVP 优先本地壁纸** |

---

## 二、技术可行性分析

### 2.1 动态壁纸实现原理

macOS 不支持直接将视频/网页设为壁纸，核心方案是：

```
创建透明全屏窗口 → 层级置于桌面图标下方 → 在窗口内渲染视频/网页
```

**关键技术点**：

| 技术点 | API/框架 | 说明 |
|--------|----------|------|
| 窗口层级控制 | `NSWindow.level` | 设为 `desktopIconWindow - 1`，显示在图标下方 |
| 视频渲染 | `AVPlayerLayer` | 硬件加速视频播放，低资源占用 |
| 网页渲染 | `WKWebView` | 原生 WebKit，支持 HTML5/WebGL |
| 桌面壁纸设置 | `NSWorkspace.shared.setDesktopImageURL` | 系统 API，设置静态壁纸 |
| 多屏幕支持 | `NSScreen.screens` | 为每个屏幕创建独立窗口 |
| 空格（Spaces）支持 | `NSWorkspace.activeSpaceDidChangeNotification` | 监听虚拟桌面切换 |

---

### 2.2 视频壁纸可行性 ✅

**方案**：AVPlayer + AVPlayerLayer

```swift
// 核心代码逻辑
let player = AVPlayer(url: videoURL)
let playerLayer = AVPlayerLayer(player: player)
playerLayer.frame = screen.frame
playerLayer.videoGravity = .resizeAspectFill

// 创建透明窗口
let window = NSWindow(
    contentRect: screen.frame,
    styleMask: .borderless,
    backing: .buffered,
    defer: false
)
window.level = NSWindow.Level(Int(CGWindowLevelKey.desktopIconWindow.rawValue) - 1)
window.backgroundColor = .clear
window.contentView?.layer?.addSublayer(playerLayer)
```

**可行性评估**：
- ✅ `AVPlayer` 硬件加速，资源占用低（~3-5% CPU）
- ✅ 支持暂停/播放控制，适合省电模式
- ✅ 支持多屏幕独立播放
- ⚠️ 需注意 macOS 14+ 的权限变化

---

### 2.3 网页壁纸可行性 ✅

**方案**：WKWebView

```swift
let webView = WKWebView(frame: screen.frame)
webView.configuration.mediaTypesRequiringUserActionForPlayback = []
webView.loadFileURL(htmlURL, allowingReadAccessTo: directoryURL)
```

**可行性评估**：
- ✅ WKWebView 原生支持，性能接近 Safari
- ✅ 支持 WebGL（Three.js 等 3D 框架自动可用）
- ✅ 支持 JavaScript 与 Swift 交互（`WKScriptMessageHandler`）
- ⚠️ 复杂网页（大量 DOM/动画）可能占用较高内存
- ⚠️ 需处理本地文件加载的沙盒权限

---

### 2.4 系统权限要求

| 权限 | 必要性 | 说明 |
|------|--------|------|
| 辅助功能权限 | ⚠️ 可选 | 某些壁纸需要模拟用户输入 |
| 屏幕录制权限 | ❌ 不需要 | 不录屏则不需要 |
| 文件访问权限 | ✅ 必需 | 读取本地视频/HTML 文件 |
| 桌面文件夹访问 | ✅ 必需 | 设置壁纸需访问 `~/Desktop` 等 |
| 后台运行权限 | ✅ 必需 | 壁纸软件需常驻后台 |

---

## 三、资源占用分析

### 3.1 空载资源占用（预估）

| 场景 | CPU | 内存 | 说明 |
|------|-----|------|------|
| 应用启动，无壁纸 | ~0.5% | ~30MB | 仅菜单栏常驻 |
| 播放 1080p 视频 | ~3-5% | ~80MB | AVPlayer 硬件加速 |
| 播放 4K 视频 | ~8-12% | ~150MB | 取决于编码格式 |
| 简单网页壁纸 | ~2-4% | ~60MB | 静态/轻量动画 |
| 复杂 WebGL 壁纸 | ~10-20% | ~120MB | 取决于网页复杂度 |

### 3.2 省电优化策略

1. **检测到全屏应用自动暂停**（游戏/演示模式）
2. **电池模式降低帧率**（网页壁纸 30fps → 15fps）
3. **视频壁纸循环播放，避免重新解码**
4. **网页壁纸用 `requestAnimationFrame` 节流**

---

## 四、与 Wallpaper Engine 的差距分析

| 功能 | Wallpaper Engine | macOS 可行性 | 差距原因 |
|------|------------------|-------------|---------|
| 视频壁纸 | ✅ | ✅ 完整支持 | AVPlayer 硬件加速成熟 |
| 网页壁纸 | ✅ | ✅ 完整支持 | WKWebView 能力接近 Chrome |
| 3D 场景壁纸 | ✅ | ❌ MVP 不支持 | 需自研 3D 引擎，成本高 |
| 音频响应壁纸 | ✅ | ⚠️ 部分支持 | 需 `AVCaptureDevice` 获取系统音频 |
| 鼠标交互壁纸 | ✅ | ✅ 支持 | WKWebView 支持 JS 交互 |
| 创意工坊社区 | ✅ | ⚠️ 需自建 | 无 Steam 生态，需自建后端 |
| 多显示器独立壁纸 | ✅ | ✅ 支持 | `NSScreen` API 完整 |

**结论**：MVP 可覆盖 WE 核心功能的 **60-70%**，差距主要在 3D 场景和社区生态。

---

## 五、分发与审核风险

### 5.1 Mac App Store 审核风险

| 风险点 | 说明 | 应对策略 |
|--------|------|---------|
| 动态壁纸实现方式 | 透明窗口可能被拒 |  sandbox 内声明必要权限 |
| 后台常驻 | 可能被认定为"无用后台" | 声明 `com.apple.security.files.user-selected.read-write` |
| 下载执行代码 | 网页壁纸可能被认为动态执行代码 | 社区壁纸需审核机制 |

**建议**：MVP 阶段走官网分发，后续再尝试 App Store。

### 5.2 官网分发方案

- 打包为 `.dmg` 文件
- 需开发者签名（`codesign`）避免 Gatekeeper 拦截
- 建议申请 Developer ID 证书（$99/年）

---

## 六、开发成本评估

| 模块 | 预估工作量 | 说明 |
|------|-----------|------|
| 壁纸渲染引擎（视频+网页） | 2-3 周 | 核心模块，需多屏幕适配 |
| 壁纸管理 UI（SwiftUI） | 2 周 | 列表、预览、设置界面 |
| 系统权限处理 | 1 周 | 权限申请、沙盒适配 |
| 社区功能后端 | 2-3 周 | Node.js + PG，含微信登录 |
| 社区功能客户端 | 1-2 周 | 壁纸浏览、下载、上传 |
| 测试与优化 | 1-2 周 | 多 macOS 版本、多屏幕 |
| **总计（MVP）** | **约 2 个月** | 单人开发 |

---

## 七、最终建议

### ✅ 推荐实施

1. **技术可行**：macOS 原生 API 完整支持动态壁纸实现
2. **资源可控**：原生技术栈，空载占用低
3. **市场空白**：Wallpaper Engine 不支持 macOS，竞争对手少
4. **扩展性强**：网页壁纸格式天然支持 WebGL 3D

### ⚠️ 主要风险

1. **App Store 审核**：动态壁纸实现方式可能违反审核指南
2. **系统更新兼容**：macOS 新版本可能限制窗口层级 API
3. **社区冷启动**：自建社区 vs Steam 创意工坊，用户基数差距大

### 📋 MVP 范围建议

- 本地视频壁纸（MP4/MOV）
- 本地/社区网页壁纸（HTML 上传）
- 多屏幕支持
- 基础壁纸管理 UI
- 微信登录 + 社区浏览/上传
