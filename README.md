# mac-right-helper

> 让 Finder 右键菜单像终端一样强大。

mac-right-helper 是一款面向开发者和高级用户的 macOS Finder 右键扩展工具。它通过原生 `NSServices` 机制，将文件操作、开发工具、系统增强等实用功能直接注入 Finder 的"服务"菜单——无需打开终端，无需安装独立的 Finder 扩展，右键文件或文件夹即可一键执行。

**核心亮点**

- **零侵入集成**：纯 `NSServices` 实现，无需 Finder Sync Extension，系统资源占用更少
- **开发工作流原生支持**：一键在 VS Code / Terminal 中打开、Git 操作、JSON 格式化
- **热重载配置**：修改菜单项或脚本后即时生效，无需重启应用
- **可编程扩展**：通过 Shell / Python / AppleScript 自定义脚本，打造专属右键菜单

---

## 功能特性

### 文件操作

| 菜单项 | 说明 |
|--------|------|
| **Copy Path** | 复制选中文件的完整路径到剪贴板 |
| **Copy File Name** | 复制选中文件的文件名到剪贴板 |
| **New File** | 在选中目录下新建空文件 |
| **Compress** | 压缩选中文件/文件夹为 `.zip` |
| **Decompress** | 解压选中的压缩文件 |
| **Move To...** | 将选中文件移动到用户选择的目录 |
| **Copy To...** | 将选中文件复制到用户选择的目录 |

### 开发工具

| 菜单项 | 说明 |
|--------|------|
| **Open in VS Code** | 在 Visual Studio Code 中打开选中文件/文件夹 |
| **Open in Terminal** | 在 Terminal 中打开选中目录 |
| **Git Init** | 在选中目录初始化 Git 仓库 |
| **Git Status** | 在 Terminal 中执行 `git status` |
| **Format JSON** | 格式化选中的 JSON 文件 |

### 系统增强

| 菜单项 | 说明 |
|--------|------|
| **Toggle Hidden Files** | 在 Finder 中切换隐藏文件显示状态 |
| **Make Executable** | 对选中文件执行 `chmod +x` |
| **Create Symlink** | 为选中文件创建符号链接 |
| **Open Parent Directory** | 打开选中文件的父目录 |

### 自定义脚本

用户可通过偏好设置窗口添加自定义 Shell、Python 或 AppleScript 脚本，扩展右键菜单功能。脚本接收选中文件路径作为参数（`$1`, `$2`...）。

---

## 系统要求与依赖

- **macOS 12.0 (Monterey)** 或更高版本
- **Xcode 14+**（可选，用于调试与测试；独立打包仅需 Swift 工具链）
- 运行时需在**系统设置 > 隐私与安全性 > 完全磁盘访问权限**中授予应用权限
- 首次使用时需在**系统设置 > 通用 > 登录项与扩展 > 服务**中勾选本应用

---

## 编译说明

本项目提供三种构建方式，可根据环境和需要选择：

### 环境要求

- **仅安装 Command Line Tools**：只能使用「方式三：独立打包」
- **已安装完整 Xcode**：三种方式均可使用

### 方式一：Xcode 构建（推荐开发调试）

> 需要完整安装 Xcode（App Store 或 Apple Developer 下载），仅 Command Line Tools 不足。

需要本地已配置好 Xcode 项目及 `mac-right-helper` scheme。

```bash
# Debug 构建
xcodebuild -scheme mac-right-helper -destination 'platform=macOS' build

# Release 构建
xcodebuild -scheme mac-right-helper -destination 'platform=macOS' -configuration Release build
```

构建产物位于 `build/Release/mac-right-helper.app`。

### 方式二：使用 build.sh（通用构建入口）

`build.sh` 是推荐的一键构建入口。它会自动检测环境：

- 如果检测到完整 Xcode，使用 `xcodebuild` 编译
- 如果只有 Command Line Tools，自动回退到 `package.sh` 的独立打包方式

```bash
./build.sh
```

构建产物位于 `build/Release/mac-right-helper.app`（Xcode）或 `build/mac-right-helper.app`（独立打包）。

### 方式三：独立打包（无需 Xcode 项目）

> 仅需 Swift 工具链（Command Line Tools 或 Xcode 均可）。

仓库内置 `package.sh`，可直接调用 `swiftc` 编译源码并生成完整的 `.app` Bundle。适用于没有完整 Xcode 或 CI 环境。

```bash
# 直接运行（脚本本身兼容 POSIX sh）
./package.sh

# 或使用 bash 显式执行
bash package.sh

# 使用 Developer ID 签名（用于对外分发）
CODE_SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./package.sh
```

`package.sh` 内部逻辑如下：

1. **收集源文件**：递归扫描 `mac-right-helper/` 目录下所有 `.swift` 文件
2. **准备 Bundle 目录**：创建 `build/mac-right-helper.app/Contents/MacOS` 和 `Resources`
3. **编译二进制**：分别调用 `swiftc` 编译 `arm64` 和 `x86_64` 两个架构的二进制（启用 `-O` 和 `-whole-module-optimization`），链接 `Foundation`、`AppKit`、`ApplicationServices` 框架；再用 `lipo` 合并为通用二进制（Universal Binary），同时支持 Apple Silicon 和 Intel Mac
4. **复制 Info.plist**：将 `mac-right-helper/Info.plist` 复制到 `Contents/Info.plist`；若源文件不存在则生成默认配置
5. **代码签名**：先尝试带 `--options runtime` 签名，失败则回退到普通深度签名
6. **验证签名**：调用 `codesign -vv --deep` 检查签名有效性
7. **输出摘要**：打印二进制体积和 Bundle 体积，并提示本地安装与分发打包命令

脚本顶部定义了以下可修改的常量：

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `APP_NAME` | `mac-right-helper` | 应用名称 |
| `BUNDLE_ID` | `com.example.mac-right-helper` | Bundle Identifier |
| `VERSION` | `1.0` | 版本号 |
| `BUILD_NUMBER` | `1` | 构建号 |
| `MIN_MACOS_VERSION` | `12.0` | 最低支持 macOS 版本 |
| `CODE_SIGN_IDENTITY` | `-`（ad-hoc） | 代码签名证书，可通过环境变量覆盖 |

构建产物位于 `build/mac-right-helper.app`。

---

## 部署说明

### 本地安装

将构建好的 `.app` 复制到 Applications 目录：

```bash
# 安装到用户目录（推荐）
cp -R build/mac-right-helper.app ~/Applications/

# 或安装到系统目录
sudo cp -R build/mac-right-helper.app /Applications/
```

首次启动时，应用会以 `LSUIElement` 后台模式运行（无 Dock 图标），状态栏会出现一个 `hand.point.up.left` 图标。

### 权限配置

1. **完全磁盘访问权限**
   打开 **系统设置 > 隐私与安全性 > 完全磁盘访问权限**，点击 `+` 添加已安装的 `mac-right-helper.app`。该权限用于执行复制路径、移动文件、压缩/解压等文件操作。

2. **辅助功能权限（可选）**
   部分系统级操作（如切换隐藏文件）需要辅助功能权限。首次执行相关操作时系统会提示授权。

3. **启用服务菜单**
   打开 **系统设置 > 通用 > 登录项与扩展 > 服务**，勾选 **mac-right-helper** 下的所有菜单项。勾选后，Finder 右键的"服务"子菜单才会显示本应用的功能。

### 打包分发

若需将应用打包为 ZIP 或 DMG 进行分发，可在执行 `package.sh` 后使用以下命令：

```bash
# 生成 ZIP
ditto -c -k --sequesterRsrc --keepParent build/mac-right-helper.app build/mac-right-helper.zip

# 生成 DMG
hdiutil create -volname "mac-right-helper" -srcfolder build/mac-right-helper.app -ov build/mac-right-helper.dmg
```

对外分发前，建议设置有效的 `CODE_SIGN_IDENTITY` 进行正式代码签名，否则用户可能遇到 Gatekeeper 拦截。

---

## 使用说明

1. **启动应用**后，状态栏会出现一个 `hand.point.up.left` 图标
   - **左键点击**：打开偏好设置窗口
   - **右键点击**：显示菜单（偏好设置 / 重新加载服务 / 退出）

2. **在 Finder 中右键**任意文件或文件夹，选择"服务"子菜单，即可看到所有可用操作

3. **配置自定义脚本**：通过偏好设置窗口添加、排序或禁用菜单项。配置保存后调用 `NSUpdateDynamicServices()` 自动热重载，无需重启应用

---

## 开发指南

### 项目结构

```
mac-right-helper/
├── main.swift                    # 应用入口，手动引导 NSApplication
├── AppDelegate.swift             # 服务路由、权限检查、状态栏初始化
├── Info.plist                    # NSServices 注册、Bundle 配置
├── Models/
│   ├── AppConfig.swift           # 配置模型（内置项 + 自定义脚本）
│   └── CustomScript.swift        # 自定义脚本模型
├── Core/
│   ├── ConfigManager.swift       # 配置持久化单例（UserDefaults）
│   ├── ScriptExecutor.swift      # Shell/Python/AppleScript 异步执行器
│   └── PermissionManager.swift   # 完全磁盘访问 + 辅助功能权限检查
├── Actions/
│   ├── ActionHandler.swift       # ActionHandler 协议定义
│   ├── ActionDispatcher.swift    # 内置操作注册表 + 自定义脚本解析
│   ├── CustomScriptHandler.swift # 自定义脚本包装器
│   ├── OpenPreferencesAction.swift
│   ├── FileActions.swift         # 文件操作处理器
│   ├── DevActions.swift          # 开发工具处理器
│   └── SystemActions.swift       # 系统增强处理器
├── UI/
│   ├── StatusBarController.swift # 状态栏图标与菜单
│   └── PreferencesWindowController.swift # 偏好设置窗口
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
```

### 添加新的内置操作

新增内置操作需要完成以下三步：

1. **实现 Handler**：在 `Actions/FileActions.swift`、`DevActions.swift` 或 `SystemActions.swift` 中实现 `ActionHandler` 协议

   ```swift
   struct MyAction: ActionHandler {
       func handle(filePaths: [String]) async throws {
           guard !filePaths.isEmpty else { return }
           // 执行操作...
       }
   }
   ```

2. **注册到分发器**：在 `ActionDispatcher.handlers` 中添加该操作到注册表

   ```swift
   "myAction": MyAction()
   ```

3. **声明服务**：在 `Info.plist` 的 `NSServices` 数组下添加对应的 `<dict>` 条目，`NSUserData` 的值必须与注册表中的 Key 完全一致

4. **编写单元测试**：覆盖空输入、正常输入和错误路径

5. **运行测试验证**：

   ```bash
   xcodebuild test -scheme mac-right-helper -destination 'platform=macOS'
   ```

### 测试

```bash
# 运行全部测试
xcodebuild test -scheme mac-right-helper -destination 'platform=macOS'

# 运行单个测试类
xcodebuild test -scheme mac-right-helper -destination 'platform=macOS' \
  -only-testing mac-right-helperTests/ConfigManagerTests

# 运行单个测试方法
xcodebuild test -scheme mac-right-helper -destination 'platform=macOS' \
  -only-testing mac-right-helperTests/ConfigManagerTests/testSaveAndLoadConfig

# 线程竞争检测（CI 推荐）
xcodebuild test -scheme mac-right-helper -destination 'platform=macOS' \
  -enableThreadSanitizer YES
```

---

## 技术细节

- 应用以 `LSUIElement` 后台代理运行，**无 Dock 图标**
- Finder 集成完全依赖 `Info.plist` 中的 `NSServices` 声明，无需独立的 Finder Sync Extension
- 使用 `NSUpdateDynamicServices()` 在运行时热重载服务列表，配置更改后无需重启应用
- 所有操作均为异步执行（`async throws`），错误通过 `NSAlert` 在主线程统一展示
- `ActionHandler` 全部采用无状态的 `struct` 实现，避免共享可变状态
- `Core/` 模块不依赖 `Actions/` 或 `UI/`，保持底层能力的独立性

---

## 权限说明

| 权限 | 用途 |
|------|------|
| **完全磁盘访问权限** | 访问用户目录下的文件以执行复制、移动、压缩等操作 |
| **辅助功能** | 部分系统级操作需要（如切换隐藏文件） |

首次启动时若未授权，应用会弹出提示并引导至系统设置。

---

## License

MIT License
