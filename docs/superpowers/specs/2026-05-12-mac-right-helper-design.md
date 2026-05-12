# mac-right-helper 设计文档

**日期**: 2026-05-12
**项目**: mac-right-helper — macOS Finder 右键菜单扩展工具
**分发方式**: 直接分发（不上架 Mac App Store）
**最低支持系统**: macOS 12 (Monterey)

---

## 1. 目标

构建一个 macOS Finder 右键扩展工具，提供文件操作、开发工具、系统增强和自定义脚本四大类功能。用户可通过独立偏好设置窗口、菜单栏图标或右键设置入口管理菜单项。

## 2. 技术选型

| 层面 | 选型 | 理由 |
|------|------|------|
| 开发语言 | Swift | macOS 原生生态，与系统 API 深度集成 |
| UI 框架 | AppKit / SwiftUI 混合 | 状态栏和复杂列表用 AppKit，配置面板可用 SwiftUI |
| Finder 集成 | Services (`NSServices`) | Finder Sync 已弃用；Services 官方支持、无需用户手动启用扩展、开发维护成本低 |
| 配置存储 | `UserDefaults` + JSON | 简单配置用 UserDefaults，复杂数据结构（自定义脚本列表）序列化为 JSON 存储 |
| 脚本执行 | `Process` + `NSAppleScript` | Shell/Python 通过 Process 执行，AppleScript 通过 NSAppleScript 桥接 |

## 3. 架构总览

```
┌─────────────────────────────────────────────────────┐
│                    用户交互层                         │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐    │
│  │ 偏好设置窗口 │  │ 菜单栏图标  │  │ 右键设置入口 │   │
│  └────────────┘  └────────────┘  └────────────┘    │
└──────────────────┬──────────────────────────────────┘
                   │ 读写配置
┌──────────────────▼──────────────────────────────────┐
│                   核心引擎层                          │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐    │
│  │ 菜单项注册器 │  │ 动作分发器  │  │ 脚本执行器  │   │
│  │ (Services) │  │            │  │ (Shell/AS) │   │
│  └────────────┘  └────────────┘  └────────────┘    │
│  ┌────────────┐  ┌────────────┐                     │
│  │ 配置持久化  │  │ 权限检查器  │                     │
│  │ (UserDefaults│ │ (Accessibility)│                 │
│  └────────────┘  └────────────┘                     │
└──────────────────┬──────────────────────────────────┘
                   │ 调用
┌──────────────────▼──────────────────────────────────┐
│                   系统能力层                          │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐    │
│  │ Finder API │  │ 终端/Shell │  │ AppleScript│    │
│  │ (Services) │  │            │  │ 桥接        │    │
│  └────────────┘  └────────────┘  └────────────┘    │
└─────────────────────────────────────────────────────┘
```

## 4. 核心模块设计

### 4.1 RightClickEngine（单例）

- 启动时读取 `UserDefaults` 配置
- 管理 `MenuItemRegistry`，决定注册哪些 Services
- 监听配置变更通知，触发服务热重载

### 4.2 MenuItemRegistry

内置菜单项按功能分组：

| 分组 | 内置项 |
|------|--------|
| 文件操作 | 复制路径、复制文件名、新建文件（支持模板）、快速压缩/解压、移动到/复制到 |
| 开发工具 | 用 VS Code 打开、用终端打开、Git Init/Status/Commit、格式化 JSON |
| 系统增强 | 显示/隐藏隐藏文件、修改文件权限、创建符号链接、打开当前目录 |
| 自定义脚本 | 用户通过配置界面添加的 Shell/Python/AppleScript 脚本 |

每个菜单项结构：
```swift
struct MenuItem {
    let id: String
    let displayName: String
    let group: MenuGroup
    let icon: String? // SF Symbol name
    let requiredPermissions: [Permission]
    let sendTypes: [String] // NSPasteboard type filters
    let action: MenuAction
    var isEnabled: Bool
    var sortWeight: Int
}
```

### 4.3 ConfigManager

- 配置键：`RightHelperMenuConfig`
- 存储内容：每项的启用状态、排序权重、自定义脚本列表
- 监听变更，发布 `NotificationCenter` 通知

### 4.4 ScriptExecutor

- **Shell**: `Process` 执行，`$1` = 首文件路径，`$@` = 全部路径
- **Python**: 通过 `/usr/bin/python3` 执行
- **AppleScript**: `NSAppleScript` 执行

### 4.5 UI 层

- **PreferencesWindow**: 分组展示菜单项，支持拖拽排序、勾选开关、添加/编辑自定义脚本
- **StatusBarController**: `NSStatusBar` 常驻，左键打开配置，右键快捷操作
- **右键设置入口**: 菜单底部常驻 "⚙️ 设置" 或 Option 键触发配置

### 4.6 PermissionManager

检查并引导用户授予：
- **Full Disk Access**: 访问受保护目录
- **Accessibility**: 高级窗口操作（如需要）
- **Automation**: 控制 Finder / 终端

## 5. 数据流与交互流程

### 5.1 首次启动

```
打开 App → 检查权限 → 缺失则引导用户跳转系统设置
         → 权限 OK → 注册 Services → 显示状态栏图标
```

### 5.2 右键执行

```
用户右键 → 系统显示 Services 菜单 → 点击菜单项
       → AppDelegate 接收 NSPasteboard → 提取文件路径
       → 分发到内置处理器或 ScriptExecutor
       → 反馈执行结果（静默 / Toast / 错误弹窗）
```

### 5.3 配置热重载

```
配置变更 → ConfigManager 保存 → 发布通知
       → RightClickEngine 重新生成 Services
       → 调用 NSUpdateDynamicServices() → 立即生效
```

## 6. 错误处理

| 场景 | 处理方式 |
|------|---------|
| 权限不足 | 弹窗提示具体权限 + "去设置"按钮跳转 |
| 脚本执行失败 | 捕获 stderr，显示简要错误 + "查看详情" |
| 选中项类型不匹配 | `NSSendTypes` 自动过滤，菜单项不显示或灰化 |
| 配置损坏 | 启动检测 JSON 有效性，损坏则重置为默认并通知用户 |
| 服务注册失败 | 日志记录 + 状态栏图标显示警告红点 |

## 7. 测试策略

- **单元测试**: ConfigManager 序列化、ScriptExecutor 参数传递、PermissionManager 状态判断
- **集成测试**: 模拟 NSPasteboard 输入，验证 Services 响应
- **手动测试**: 真实 Finder 环境测试所有菜单项、权限场景、macOS 版本兼容性

## 8. 内置功能清单

### 8.1 文件操作
- 复制路径（POSIX / HFS / URL 格式）
- 复制文件名
- 新建文件（支持模板：txt、md、py、swift 等）
- 快速压缩（zip）
- 快速解压
- 移动到…（弹出目标选择器）
- 复制到…

### 8.2 开发工具
- 用 VS Code 打开
- 用终端打开（iTerm/Terminal 可配置）
- Git Init
- Git Status（弹出终端执行）
- 格式化 JSON（选中 json 文件时显示）

### 8.3 系统增强
- 显示/隐藏隐藏文件（切换 Finder 设置）
- 修改文件权限（弹出权限面板）
- 创建符号链接
- 打开当前目录（在 Finder 中打开父目录）

### 8.4 自定义脚本
- 用户可添加 Shell/Python/AppleScript 脚本
- 脚本接收 `$1`（首个文件）、`$@`（全部文件）作为参数
- 可配置显示名称、图标、适用的文件类型

## 9. 配置格式草案

```json
{
  "version": 1,
  "builtinItems": {
    "copyPath": { "enabled": true, "weight": 10 },
    "openInVSCode": { "enabled": true, "weight": 20 }
  },
  "customScripts": [
    {
      "id": "custom-uuid",
      "name": "上传到图床",
      "type": "shell",
      "source": "#!/bin/bash\n...",
      "icon": "cloud.upload",
      "sendTypes": ["public.image"],
      "weight": 100
    }
  ]
}
```
