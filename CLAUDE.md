# mac-right-helper 开发指南

## 项目概述

mac-right-helper 是一个 macOS Finder 右键扩展工具，通过 macOS 的 `NSServices` 机制将实用操作注入 Finder 的"服务"菜单。用户无需离开 Finder 即可执行常用文件操作、开发工具和系统增强功能。

## 架构

```
┌─────────────────────────────────────────┐
│              main.swift                 │  ← 手动引导 NSApplication 入口
├─────────────────────────────────────────┤
│           AppDelegate.swift             │  ← 服务路由与权限检查
├─────────────────────────────────────────┤
│              Info.plist                 │  ← NSServices 声明
├─────────────────────────────────────────┤
│              Models/                    │
│           ├── AppConfig.swift           │  ← 配置模型（Codable）
│           └── CustomScript.swift        │  ← 自定义脚本模型
├─────────────────────────────────────────┤
│               Core/                     │
│         ├── ConfigManager.swift         │  ← UserDefaults 单例持久化
│         ├── ScriptExecutor.swift        │  ← 异步 Shell/Python/AppleScript 执行器
│         └── PermissionManager.swift     │  ← 完全磁盘访问 + 辅助功能权限检查
├─────────────────────────────────────────┤
│              Actions/                   │
│         ├── ActionHandler.swift         │  ← 协议定义
│         ├── ActionDispatcher.swift      │  ← 注册表 + 分发 + 错误展示
│         ├── CustomScriptHandler.swift   │  ← 自定义脚本包装器
│         ├── OpenPreferencesAction.swift │  ← 打开偏好设置窗口
│         ├── FileActions.swift           │  ← 文件操作（复制、压缩、移动等）
│         ├── DevActions.swift            │  ← 开发工具（VS Code、Git、JSON 等）
│         └── SystemActions.swift         │  ← 系统增强（隐藏文件、chmod 等）
├─────────────────────────────────────────┤
│                 UI/                     │
│       ├── StatusBarController.swift     │  ← 状态栏图标（左键/右键区分）
│       └── PreferencesWindowController.swift  ← 偏好设置窗口（NSTableView）
├─────────────────────────────────────────┤
│               Utils/                    │
│         └── PasteboardReader.swift      │  ← 从 NSPasteboard 提取文件路径
├─────────────────────────────────────────┤
│           mac-right-helperTests/        │  ← XCTest 测试目标
└─────────────────────────────────────────┘
```

### 核心设计原则

**`Actions/` 中的 Handler 是纯值类型。** 所有内置的 `ActionHandler` 实现都应为 `struct`。它们接收文件路径，通过 `ScriptExecutor` 或 API 执行任务，不持有任何可变共享状态。

**`ActionDispatcher` 是唯一分发点。** 它将 `userData`（操作 ID）解析为静态内置注册表中的 Handler，或在运行时构造 `CustomScriptHandler`。所有错误统一在主线程通过 `NSAlert` 展示。

**`Core/` 不得导入 `Actions/` 或 `UI/`。** 配置、脚本执行、权限检查是与框架无关的基础能力。依赖方向如下：
```
main.swift → AppDelegate → UI/, Actions/, Core/
Actions/*  → Core/       （不得依赖其他 Action 组或 UI）
UI/*       → Core/       （不得依赖 Actions/）
Core/      → 仅 Foundation/AppKit
```

**配置变更支持热重载。** `ConfigManager` 发出 `RightHelperConfigChanged` 通知，`AppDelegate` 调用 `NSUpdateDynamicServices()`，Finder 菜单无需重启应用即可更新。

### 核心类型

- **`ActionHandler`** — 内置或自定义操作（异步 `handle(filePaths:)`）
- **`ActionDispatcher`** — 解析操作 ID → Handler，通过 `NSAlert` 展示错误
- **`ConfigManager`** — 单例，将 `AppConfig` 持久化到 `UserDefaults`
- **`ScriptExecutor`** — 异步 Shell/Python/AppleScript 执行器
- **`PasteboardReader`** — 从 `NSPasteboard` 提取文件路径

## 开发规则

### 1. ActionHandler 必须是值类型

所有内置 Handler 都应使用 `struct`。Handler 调用之间不共享可变状态。

```swift
// 错误 — 带可变状态的 class
class CopyPathAction: ActionHandler {
    var count = 0
    func handle(filePaths: [String]) async throws { count += 1 }
}

// 正确 — 无状态 struct
struct CopyPathAction: ActionHandler {
    func handle(filePaths: [String]) async throws { /* ... */ }
}
```

### 2. 错误必须在主线程通过 ActionDispatcher 展示

`ActionHandler` 内部不得直接显示 `NSAlert`。应抛出错误，由 `ActionDispatcher` 统一处理。

```swift
// 错误 — Handler 直接展示 UI
struct BadAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        if filePaths.isEmpty {
            await MainActor.run {
                NSAlert(error: MyError.empty).runModal()  // 禁止
            }
        }
    }
}

// 正确 — 抛出，让分发器处理
struct GoodAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard !filePaths.isEmpty else { throw MyError.empty }
    }
}
```

### 3. 空输入应尽早返回，不抛异常

在 `handle(filePaths:)` 内部，使用 `guard` 对空输入静默返回。抛出异常仅用于真正的失败场景。

```swift
// 错误 — 空输入抛异常
func handle(filePaths: [String]) async throws {
    guard !filePaths.isEmpty else { throw ActionError.noSelection }
}

// 正确 — 静默无操作
func handle(filePaths: [String]) async throws {
    guard !filePaths.isEmpty else { return }
}
```

### 4. 新增内置操作需要三步

1. 在合适的 `Actions/*.swift` 文件中实现 `ActionHandler`
2. 在 `ActionDispatcher.handlers` 中注册
3. 在 `Info.plist` 的 `NSServices` 下添加对应的 `<dict>` 条目

遗漏第 3 步将导致 Finder 菜单中不显示该选项。

### 5. UI 操作必须使用 `await MainActor.run`

任何 `NSAlert`、`NSOpenPanel` 或窗口操作都必须在主线程执行。

```swift
// 错误 — 可能在后台线程执行
NSAlert(error: err).runModal()

// 正确
await MainActor.run {
    NSAlert(error: err).runModal()
}
```

### 6. 测试隔离是强制的

- `ConfigManagerTests` 在 `setUp` 中清除 `UserDefaults` 的目标键
- `PasteboardReaderTests` 使用命名 `NSPasteboard`（如 `"test"`）；禁止操作系统默认剪贴板
- 临时测试文件写入 `/tmp/`，并在 `tearDown` 中清理

## 代码风格

- 遵循标准 Swift 规范（尽可能使用 `swift-format`）
- 除非需要引用语义，否则**优先使用 `struct` 而非 `class`**
- 类型名使用 `PascalCase`，方法/变量使用 `camelCase`
- 避免使用 `import Cocoa`；显式导入 `Foundation` 或 `AppKit`
- 保持函数聚焦；超过约 60 行时提取辅助函数
- 单例模式：`static let shared`
- `main.swift` 是唯一入口点；`AppDelegate` 不得使用 `@main`

## 测试

### 基本要求

- 所有新功能必须包含单元测试
- 所有 Bug 修复应包含回归测试
- 提交前测试必须通过：`xcodebuild test -scheme mac-right-helper -destination 'platform=macOS'`

### 运行测试

```bash
# 完整测试套件
xcodebuild test -scheme mac-right-helper -destination 'platform=macOS'

# 指定测试类
xcodebuild test -scheme mac-right-helper -destination 'platform=macOS' \
  -only-testing mac-right-helperTests/ConfigManagerTests

# 指定测试方法
xcodebuild test -scheme mac-right-helper -destination 'platform=macOS' \
  -only-testing mac-right-helperTests/ConfigManagerTests/testSaveAndLoadConfig

# 线程竞争检测（CI）
xcodebuild test -scheme mac-right-helper -destination 'platform=macOS' \
  -enableThreadSanitizer YES
```

### 测试模式

- `ActionHandler` 实现至少覆盖：空输入、正常输入、错误路径
- `ActionDispatcher` 至少覆盖：内置操作解析、自定义脚本解析、未知操作返回 `nil`
- `ScriptExecutor` 至少覆盖：Shell/Python/AppleScript 成功执行、Shell 失败抛出
- `ConfigManager` 至少覆盖：默认配置加载、保存与重新加载、自定义脚本往返
- 对 `async throws` API 使用 `async` 测试方法；对期望抛出异常的路径使用 `do/try/catch` + `XCTFail`

## 构建

```bash
# Release 构建（通过构建脚本）
./build.sh

# Release 构建（通过 xcodebuild）
xcodebuild -scheme mac-right-helper -destination 'platform=macOS' -configuration Release build

# 独立打包（无需 Xcode 项目）
./package.sh
```

**注意：** `.xcodeproj` 不在本仓库中跟踪。构建脚本假设本地 Xcode 项目中存在一个名为 `mac-right-helper` 的 scheme。

## 提交前检查清单

1. **构建通过**：`xcodebuild -scheme mac-right-helper -destination 'platform=macOS' build`
2. **测试通过**：`xcodebuild test -scheme mac-right-helper -destination 'platform=macOS'`
3. **无死代码**：未使用的类型或不可达代码已删除
4. **新操作在三处注册**：Handler 实现、`ActionDispatcher.handlers`、`Info.plist`
5. **为新代码添加测试**：单元测试覆盖正常路径、空输入和错误路径

## 添加新的内置操作

1. 在合适的 `Actions/*.swift` 文件中实现 `ActionHandler`（如文件操作放入 `FileActions.swift`）
2. 在 `ActionDispatcher.handlers` 中注册该 Handler
3. 在 `Info.plist` 的 `NSServices` 下添加 `<dict>` 条目，`NSUserData` 与操作 ID 一致
4. 添加单元测试，覆盖空输入、正常输入和错误路径
5. 运行 `xcodebuild test` 验证
