# CLAUDE.md

本文档为 Claude Code (claude.ai/code) 在本仓库中工作时提供指导。

## 项目概述

mac-right-helper 是一个基于 Swift 构建的 macOS Finder 右键扩展工具。它将文件操作、开发工具、系统增强功能和自定义脚本添加到 macOS 的"服务"菜单（Finder 右键）中。该应用以后台代理 (`LSUIElement`) 的形式运行，带有状态栏图标和偏好设置窗口。

Finder 集成功能通过在 `Info.plist` 中声明的 `NSServices` 实现 —— 没有单独的 Finder Sync 扩展目标。所有服务都通过 `AppDelegate.handleService(_:userData:)` 进行路由。

最低支持的 macOS 版本：12.0 (Monterey)。

## 构建与测试命令

**构建 (Release)：**
```bash
./build.sh
```

**构建并测试 (需要 Xcode 项目)：**
```bash
xcodebuild test -scheme mac-right-helper -destination 'platform=macOS'
```

**运行单个测试类：**
```bash
xcodebuild test -scheme mac-right-helper -destination 'platform=macOS' -only-testing mac-right-helperTests/ConfigManagerTests
```

**运行单个测试方法：**
```bash
xcodebuild test -scheme mac-right-helper -destination 'platform=macOS' -only-testing mac-right-helperTests/ConfigManagerTests/testSaveAndLoadConfig
```

**构建 (Release 通过 xcodebuild)：**
```bash
xcodebuild -scheme mac-right-helper -destination 'platform=macOS' -configuration Release build
```

**注意：** Xcode 项目文件 (`.xcodeproj`) 不在本仓库中跟踪。构建脚本假设在本地 Xcode 项目中存在一个名为 `mac-right-helper` 的 scheme。

## 高层架构

### 入口点与服务路由

- `main.swift` 手动引导 `NSApplication.shared` 并设置 `AppDelegate`，然后调用 `app.run()`。它**不使用** `@main` 或 `NSApplicationMain`。
- `AppDelegate.applicationDidFinishLaunching` 初始化 `StatusBarController`，检查权限，并通过 `NSUpdateDynamicServices()` 注册动态服务。
- `AppDelegate.handleService(_:userData:)` 是**所有 Finder 右键操作的单一入口点**。它接收一个 `NSPasteboard`，通过 `PasteboardReader` 提取文件路径，并使用 `userData` 作为操作 ID 分派给 `ActionDispatcher`。由于 `handleService` 是一个同步的 NSServices 回调，它在内部将异步的 `ActionDispatcher.dispatch` 包装在一个 `Task` 中。

### 配置系统

- `ConfigManager` 是一个单例，它将 `AppConfig` 持久化到 `UserDefaults` 中，键名为 `RightHelperMenuConfig`。
- `AppConfig` 是一个 `Codable` 结构体，包含：
  - `builtinItems`：操作 ID 到 `BuiltinItemConfig`（启用标志 + 排序权重）的映射
  - `customScripts`：用户定义脚本的数组
- 当配置发生变化时，`ConfigManager` 会发送 `Notification.Name("RightHelperConfigChanged")` 通知；`AppDelegate` 监听该通知并调用 `NSUpdateDynamicServices()` 以热重载服务。
- `ConfigManager` 的测试在 `setUp` 中**清除 `UserDefaults`**，以避免跨测试污染。

### 操作分发系统

- `ActionDispatcher` 维护了一个**静态编译时注册表** (`handlers: [String: ActionHandler]`)，其中包含内置的操作实例。自定义脚本在运行时通过从 `ConfigManager.shared.config.customScripts` 中查找脚本 ID 并构造一个 `CustomScriptHandler` 来解析。
- 所有处理程序都实现 `ActionHandler.handle(filePaths:)` 并以 `async` 方式运行。错误会通过主线程上的 `NSAlert` 向用户展示。
- 内置操作按功能分组：
  - `FileActions.swift` — 复制路径/文件名、新建文件、压缩/解压、移动到/复制到
  - `DevActions.swift` — 在 VS Code/Terminal 中打开、git init/status、格式化 JSON
  - `SystemActions.swift` — 切换隐藏文件、chmod、创建符号链接、打开父目录

### 脚本执行

- `ScriptExecutor` 提供以下异步方法：
  - `executeShell(script:arguments:)` — 通过 `/bin/zsh` 运行
  - `executePython(script:arguments:)` — 通过 `/usr/bin/python3` 运行
  - `executeAppleScript(source:)` — 通过 `NSAppleScript` 运行
- Shell/Python 脚本将文件路径作为 `$1`、`$2` 等接收（`arguments` 数组在 `-c` 标志之后附加）。

### 权限模型

- `PermissionManager` 通过探测 `~/Library/Safari` 检查完全磁盘访问权限，并通过 `AXIsProcessTrustedWithOptions` 检查辅助功能权限。
- 如果未授予完全磁盘访问权限，`AppDelegate` 会在启动时显示一个阻塞式的 `NSAlert`，并带有直接打开系统设置的按钮。

### UI 层

- `StatusBarController` — `NSStatusBar` 图标，系统符号为 `hand.point.up.left`。左键直接打开偏好设置窗口；右键显示菜单（偏好设置、重新加载服务、退出）。这是通过调用 `sendAction(on: [.leftMouseUp, .rightMouseUp])` 并在点击处理程序中检查 `NSApp.currentEvent!.type` 实现的。
- `PreferencesWindowController` / `PreferencesViewController` — 基于 `NSTableView` 的最小化偏好设置窗口，用于列出菜单项。目前尚未完全实现拖拽重新排序或复选框切换功能；表格目前仅显示项目名称。

### Info.plist 与服务注册

- 所有 Finder 菜单项都在 `Info.plist` 中的 `NSServices` 下静态声明。每个服务将 `NSUserData` 映射到一个操作 ID。
- `NSUpdateDynamicServices()` 在启动时和配置更改后被调用，以刷新"服务"菜单。
- **重要：** 添加新的内置操作需要：
  1. 在适当的 `Actions/*.swift` 文件中实现 `ActionHandler`
  2. 在 `ActionDispatcher.handlers` 中注册它
  3. 在 `Info.plist` 的 `NSServices` 下添加相应的 `<dict>` 条目

## 测试说明

- 测试使用 `@testable import mac_right_helper`。
- 测试覆盖范围包括：`ConfigManager`（UserDefaults 往返）、`PasteboardReader`（从剪贴板提取路径）、`ScriptExecutor`（Shell 执行和失败处理）和 `PermissionManager`（状态枚举值）。
- `ConfigManagerTests` 在 `setUp` 中清除 `UserDefaults.standard` 中的 `"RightHelperMenuConfig"`。
- `PasteboardReaderTests` 创建一个命名的 `NSPasteboard` ("test")，以避免干扰系统剪贴板。
- 仓库中没有 Xcode 项目；运行测试需要一个配置了 scheme 的本地 `.xcodeproj`。
