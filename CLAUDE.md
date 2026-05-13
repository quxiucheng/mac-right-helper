# CLAUDE.md

本文档为 Claude Code (claude.ai/code) 在本仓库中工作时提供指导。

## 项目介绍

mac-right-helper 是一个 macOS Finder 右键扩展工具，使用 Swift 开发。它通过 macOS 的 `NSServices` 机制将一系列实用功能注入 Finder 的"服务"菜单，让用户在右键文件/文件夹时即可执行常用操作，无需打开终端或额外的应用程序。

### 核心能力

- **文件操作**：复制路径/文件名、新建文件、压缩/解压、移动/复制到指定目录
- **开发工具**：在 VS Code 或 Terminal 中打开、Git 初始化/状态查看、JSON 格式化
- **系统增强**：切换隐藏文件显示、修改文件权限（chmod +x）、创建符号链接、打开父目录
- **自定义脚本**：用户可配置 Shell、Python、AppleScript 脚本，扩展右键菜单

### 技术背景

- 应用以 `LSUIElement` 后台代理运行，无 Dock 图标，仅通过状态栏图标提供入口
- Finder 集成完全依赖 `Info.plist` 中的 `NSServices` 声明，无需独立的 Finder Sync Extension 目标
- 最低支持 macOS 12.0 (Monterey)
- 使用 `NSUpdateDynamicServices()` 在运行时热重载服务列表，配置更改后无需重启应用

## 目录结构

```
mac-right-helper/
├── main.swift                    # 应用入口，手动引导 NSApplication
├── AppDelegate.swift             # NSApplicationDelegate，服务路由与权限检查
├── Info.plist                    # NSServices 注册、Bundle 配置
├── Models/
│   ├── AppConfig.swift           # 配置模型（Codable）：内置项 + 自定义脚本
│   └── CustomScript.swift        # 自定义脚本模型：id、类型、源码等
├── Core/
│   ├── ConfigManager.swift       # 配置持久化单例（UserDefaults）
│   ├── ScriptExecutor.swift      # Shell/Python/AppleScript 异步执行器
│   └── PermissionManager.swift   # 完全磁盘访问 + 辅助功能权限检查
├── Actions/
│   ├── ActionHandler.swift       # ActionHandler 协议定义
│   ├── ActionDispatcher.swift    # 内置操作注册表 + 自定义脚本解析 + 错误展示
│   ├── CustomScriptHandler.swift # 自定义脚本 ActionHandler 包装器
│   ├── OpenPreferencesAction.swift # 打开偏好设置窗口
│   ├── FileActions.swift         # 文件操作处理器（复制、压缩、移动等）
│   ├── DevActions.swift          # 开发工具处理器（VS Code、Git、JSON 等）
│   └── SystemActions.swift       # 系统增强处理器（隐藏文件、chmod 等）
├── UI/
│   ├── StatusBarController.swift # 状态栏图标与菜单（左键/右键区分）
│   └── PreferencesWindowController.swift # 偏好设置窗口（NSTableView）
└── Utils/
    └── PasteboardReader.swift    # 从 NSPasteboard 提取文件路径

mac-right-helperTests/            # XCTest 测试目标
├── ConfigManagerTests.swift
├── PasteboardReaderTests.swift
├── ScriptExecutorTests.swift
├── PermissionManagerTests.swift
├── ActionDispatcherTests.swift
├── CustomScriptHandlerTests.swift
└── OpenPreferencesActionTests.swift

build.sh                          # Release 构建脚本
```

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

## 测试规范

### 基本要求

- **每次代码变更后必须编写对应的单元测试**。新增功能、修复 bug、重构代码均不例外。
- 测试目标名为 `mac-right-helperTests`，测试类使用 `@testable import mac_right_helper`。
- 测试类命名规则：`{被测类型名}Tests`，继承 `XCTestCase`。
- 测试方法命名规则：`test{被测行为描述}`，如 `testSaveAndLoadConfig`、`testHandleShellScriptFailure`。

### 测试组织

- 每个源文件对应一个测试文件，存放在 `mac-right-helperTests/` 根目录下（目前不分子目录）。
- 一个测试方法只验证**一个行为点**，避免多断言堆叠。
- 对正常路径、边界条件、错误路径分别编写独立测试。

### 测试隔离

- **UserDefaults**：`ConfigManagerTests` 在 `setUp` 中清除 `UserDefaults.standard` 的目标键，避免测试间状态污染。
- **剪贴板**：`PasteboardReaderTests` 使用命名 `NSPasteboard`（如 `"test"`），禁止直接操作系统默认剪贴板。
- **文件系统**：临时测试文件应放在 `/tmp/` 并在测试结束后清理；避免写入用户真实目录。
- **权限相关**：`PermissionManager` 的状态依赖于外部环境，测试只验证返回值属于有效枚举范围，不做硬性断言。

### 异步测试

- 使用 `async` 测试方法直接调用 `async throws` 的 API，XCTest 会自动等待完成。
- 对期望抛出异常的路径，使用 `do/try/catch` 并在未抛出时调用 `XCTFail`。

### UI 测试

- 由于项目以 `LSUIElement` 运行且 UI 层较薄，目前以单元测试为主。
- UI 相关类型（如 `OpenPreferencesAction`）的测试只需验证不抛出异常即可，不做窗口状态断言。

### 覆盖率目标

- 所有 `ActionHandler` 实现至少覆盖：空输入处理、正常输入、错误路径（如脚本执行失败）。
- `ActionDispatcher` 至少覆盖：内置 action 解析、自定义脚本解析、未知 action 返回 nil。
- `ScriptExecutor` 至少覆盖：Shell/Python/AppleScript 成功执行、Shell 失败抛出。
- `ConfigManager` 至少覆盖：默认配置加载、配置保存与重新加载、自定义脚本往返。

## 编码规范

### 文件组织

- 按功能将文件放入子目录：`Models/`、`Core/`、`Actions/`、`UI/`、`Utils/`。
- 每个 Swift 文件只应包含单一职责的类型或逻辑。
- **禁止**将未使用的模型或死代码留在仓库中。如果类型当前没有被引用，应删除它。

### 命名规范

- 类型名使用 `PascalCase`（如 `CopyPathAction`）。
- 方法、变量、属性使用 `camelCase`（如 `handle(filePaths:)`）。
- 协议名使用名词或 `-ing` 形式（如 `ActionHandler`）。
- 枚举的 case 使用 `camelCase`（如 `fileOperations`）。

### 类型设计

- **优先使用 `struct`** 而非 `class`，除非需要引用语义或继承。所有内置操作处理器（`ActionHandler` 的实现）都应为 `struct`。
- 单例使用 `static let shared` 模式（如 `ConfigManager.shared`）。
- 使用 `enum` 承载命名空间或状态分类（如 `MenuGroup`、`PermissionStatus`）。

### 协议与实现分离

- 协议定义应存放在独立的文件中（如 `ActionHandler.swift` 只包含协议）。
- 调度器、通用 Handler 实现应与协议分开存放。
- 每个具体的 `ActionHandler` 实现按功能分组到对应的 `Actions/*.swift` 文件中。

### 错误处理

- 异步操作统一使用 `async throws` 签名。
- 错误向上抛给调用方，由 `ActionDispatcher.dispatch` 统一通过 `NSAlert` 在主线程展示。
- 在 `ActionHandler.handle(filePaths:)` 内部，对空输入使用 `guard let ... else { return }` 尽早返回，而非抛出错误。

### UI 与主线程

- 所有 UI 操作（如 `NSOpenPanel.runModal()`、`NSAlert.runModal()`）必须在主线程执行，使用 `await MainActor.run { ... }` 包装。
- 状态栏、窗口控制器等 UI 类的初始化放在 `AppDelegate.applicationDidFinishLaunching` 中完成。

### 访问控制

- 不添加不必要的访问控制修饰符；默认 `internal` 即可。
- 仅在需要隐藏实现细节时使用 `private`（如 `StatusBarController` 中的 `setupMenu()`）。

### 导入语句

- 只导入实际需要的模块。`Foundation` 是基础；需要 AppKit 时才导入 `AppKit`。
- 避免使用 `import Cocoa` 这种大包导入，应显式导入 `AppKit`。

### 入口点

- `main.swift` 是唯一的应用入口点，手动引导 `NSApplication.shared`。
- `AppDelegate` **不得**使用 `@main` 注解，避免与 `main.swift` 的引导逻辑冲突。
