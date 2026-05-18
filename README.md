# mac-right-helper

> 让 Finder 右键菜单像终端一样强大。

mac-right-helper 是一款面向开发者和高级用户的 macOS Finder 右键扩展工具。它通过原生 `NSServices` 机制，将文件操作、开发工具、系统增强等实用功能直接注入 Finder 的"服务"菜单——无需打开终端，无需安装独立的 Finder 扩展，右键文件或文件夹即可一键执行。

**核心亮点**

- **零侵入集成**：纯 `NSServices` 实现，无需 Finder Sync Extension，系统资源占用更少
- **开发工作流原生支持**：一键在 VS Code / Terminal / iTerm2 / Sublime Text / Warp / IntelliJ IDEA 中打开、Git 操作、JSON 格式化
- **热重载配置**：修改菜单项或脚本后即时生效，无需重启应用
- **可编程扩展**：通过 Shell / Python / AppleScript 自定义脚本，打造专属右键菜单
- **丰富的内置操作**：7 大类别 43+ 项内置操作，覆盖文件管理、开发工具、图像处理、翻译服务等
- **偏好设置窗口**：6 个标签页全面管理所有配置项，支持中英文双语
- **Universal Binary**：同时支持 Apple Silicon 和 Intel Mac

---

## 功能特性

### 文件操作 (File)

| 菜单项 | 说明 |
|--------|------|
| **Copy Path** | 复制选中文件的完整路径到剪贴板 |
| **Copy File Name** | 复制选中文件的文件名到剪贴板 |
| **New File** | 在选中目录下新建空文本文件（`Untitled.txt`） |
| **New File with Template** | 使用预置模板在选中目录下新建文件（支持自定义模板） |
| **New Folder from File Name** | 以选中文件的文件名创建同名文件夹 |
| **Compress** | 压缩选中文件/文件夹为 `.zip` |
| **Decompress** | 解压选中的压缩文件到当前目录 |
| **Move To...** | 将选中文件移动到用户选择的目录 |
| **Copy To...** | 将选中文件复制到用户选择的目录 |
| **Cut Files** | 剪切选中文件到剪贴板（可选置灰隐藏标记） |
| **Send To...** | 将选中文件发送到收藏夹中的目标文件夹 |
| **Send Alias to Desktop** | 在桌面创建选中文件的替身（别名） |
| **Trash Permanently** | 永久删除选中文件（可选确认提示） |
| **Favorite Directory Picker** | 快速打开收藏的常用目录 |
| **Show File Info** | 显示文件哈希信息（MD5 / SHA1 / SHA256 / SHA512），一键复制 |
| **AirDrop** | 通过 AirDrop 分享选中文件 |

### 开发工具 (Dev)

| 菜单项 | 说明 |
|--------|------|
| **Open in VS Code** | 在 Visual Studio Code 中打开选中文件/文件夹 |
| **Open in Terminal** | 在 Terminal 中打开选中目录（支持新窗口/新标签页） |
| **Open in iTerm2** | 在 iTerm2 中打开选中目录（支持新窗口/新标签页） |
| **Open in Sublime Text** | 在 Sublime Text 中打开选中目录 |
| **Open in Warp** | 在 Warp 终端中打开选中目录 |
| **Open in IntelliJ IDEA** | 在 IntelliJ IDEA 中打开选中目录 |
| **Git Init** | 在选中目录初始化 Git 仓库 |
| **Git Status** | 在 Terminal 中打开并执行 `git status` |
| **Format JSON** | 格式化选中的 JSON 文件（原地美化） |

偏好设置中提供"默认编辑器"选项，可统一切换打开编辑器的默认行为。Terminal / iTerm2 支持新窗口或新标签页两种打开模式。

### 系统增强 (System)

| 菜单项 | 说明 |
|--------|------|
| **Toggle Hidden Files** | 在 Finder 中全局切换隐藏文件显示状态 |
| **Hide Selected Files** | 隐藏选中的文件/文件夹（设置隐藏标志位） |
| **Unhide Selected Files** | 取消选中文件/文件夹的隐藏状态 |
| **Make Executable** | 对选中文件执行 `chmod +x` |
| **Create Symlink** | 为选中的两个文件创建符号链接（首个为目标，其余为链接） |
| **Open Parent Directory** | 在 Finder 中打开选中文件的父目录 |

### 图像处理 (Image)

| 菜单项 | 说明 |
|--------|------|
| **Convert to ICNS** | 将选中图片转换为 macOS 图标格式 `.icns` |
| **Convert to iOS Icons** | 将选中图片转换为 iOS 应用图标集（`ios.iconset`） |
| **Convert to Mac Icons** | 将选中图片转换为 macOS 应用图标集（`mac.iconset`） |
| **Set Custom Icon** | 将图片设置为文件/文件夹的自定义图标（需选中图片 + 目标） |

### 在线服务 (Service)

| 菜单项 | 说明 |
|--------|------|
| **Translate (Baidu)** | 通过百度翻译选中文文件内容或文件名 |
| **Translate (Google)** | 通过 Google 翻译选中文文件内容或文件名 |
| **Generate QR Code** | 将文件内容或文件名生成二维码到剪贴板 |

### iShot 集成

| 菜单项 | 说明 |
|--------|------|
| **Screenshot** | 调用 iShot 进行截图 |
| **Annotate** | 在 iShot 中打开选中图片进行标注 |

需要安装 [iShot](https://apps.apple.com/app/id1485844094) 才能使用这两个操作，未安装时会弹出提示。

### 自定义脚本

用户可通过偏好设置窗口添加自定义 Shell、Python 或 AppleScript 脚本，扩展右键菜单功能。每个脚本可配置名称、类型和源代码。脚本参数通过 `$1`, `$2`... 传递选中的文件路径。

### 文件模板

内置文件模板功能，在选中目录右键即可按模板创建新文件。支持自定义模板名称、文件扩展名和初始内容。内置默认模板：Text（`.txt`）。

### 收藏夹功能

- **收藏文件夹**：配置常用目标目录，"发送到收藏夹"操作可快速将文件复制到这些目录
- **收藏目录**：配置常用路径，"收藏目录选择器"可快速跳转到这些目录

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
- 如果只有 Command Line Tools，自动回退到独立打包方式（通过 `swiftc` 直接编译）

```bash
# 直接运行
./build.sh

# 使用 Developer ID 签名（用于对外分发）
CODE_SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./build.sh
```

构建产物位于 `build/Release/mac-right-helper.app`（Xcode）或 `build/mac-right-helper.app`（独立打包）。

**独立打包模式内部逻辑：**

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

若需将应用打包为 ZIP 或 DMG 进行分发，可在执行 `build.sh` 后使用以下命令：

```bash
# 生成 ZIP
ditto -c -k --sequesterRsrc --keepParent build/mac-right-helper.app build/mac-right-helper.zip

# 生成 DMG
hdiutil create -volname "mac-right-helper" -srcfolder build/mac-right-helper.app -ov build/mac-right-helper.dmg
```

对外分发前，建议设置有效的 `CODE_SIGN_IDENTITY` 进行正式代码签名，否则用户可能遇到 Gatekeeper 拦截。

---

## 使用说明

### 状态栏菜单

启动应用后，状态栏会出现一个 `hand.point.up.left` 图标：

- **左键点击**：打开偏好设置窗口
- **右键点击**：显示菜单（偏好设置 / 重新加载服务 / 退出）

### 偏好设置（6 个标签页）

| 标签页 | 功能 |
|--------|------|
| **通用 (General)** | 状态栏图标显隐、永久删除确认、剪切文件置灰标记、终端打开模式（新窗口/新标签页）、默认编辑器选择、语言切换（中文/English） |
| **操作 (Actions)** | 查看所有内置操作列表，按分组浏览，一键启用/禁用任意菜单项 |
| **模板 (Templates)** | 管理文件模板——新建、编辑、删除模板（名称、扩展名、内容） |
| **收藏文件夹 (Folders)** | 管理"发送到收藏夹"的目标文件夹 |
| **收藏目录 (Directories)** | 管理快速跳转的常用目录 |
| **脚本 (Scripts)** | 管理自定义脚本——新建、编辑、删除 Shell/Python/AppleScript 脚本 |

所有配置修改即时保存到 `UserDefaults`，并通过 `NSUpdateDynamicServices()` 热重载 Finder 服务菜单，无需重启应用。

### 在 Finder 中使用

1. 在 Finder 中右键选中任意文件或文件夹
2. 选择"服务"子菜单
3. 点击任意操作即可执行

---

## 开发指南

### 项目结构

```
mac-right-helper/
├── main.swift                    # 应用入口，手动引导 NSApplication
├── AppDelegate.swift             # 服务路由、权限检查、状态栏初始化
├── Info.plist                    # NSServices 注册、Bundle 配置
├── Models/
│   ├── AppConfig.swift           # 配置模型（内置项 + 自定义脚本 + 模板 + 收藏夹 + 设置）
│   └── CustomScript.swift        # 自定义脚本模型（Shell / Python / AppleScript）
├── Core/
│   ├── ConfigManager.swift       # 配置持久化单例（UserDefaults）
│   ├── ScriptExecutor.swift      # Shell / Python / AppleScript 异步执行器
│   └── PermissionManager.swift   # 完全磁盘访问 + 辅助功能权限检查
├── Actions/
│   ├── ActionHandler.swift       # ActionHandler 协议定义
│   ├── ActionDispatcher.swift    # 内置操作注册表 + 动态操作 + 自定义脚本解析
│   ├── CustomScriptHandler.swift # 自定义脚本包装器
│   ├── FileActions.swift         # 文件操作（Copy Path, Compress, Move To 等）
│   ├── ClipboardActions.swift    # 剪贴板操作（Cut Files）
│   ├── SendToActions.swift       # 发送操作（Send To Picker, Send Alias to Desktop）
│   ├── TrashActions.swift        # 永久删除操作
│   ├── FileInfoActions.swift     # 文件哈希信息展示
│   ├── AirDropAction.swift       # AirDrop 分享操作
│   ├── TemplateActions.swift     # 模板文件创建操作
│   ├── FavoriteDirActions.swift  # 收藏目录选择器
│   ├── DevActions.swift          # 开发工具（VS Code, Git, JSON 等）
│   ├── EditorActions.swift       # 编辑器打开操作（Terminal, iTerm2, Sublime Text 等）
│   ├── SystemActions.swift       # 系统增强（chmod, symlink, Toggle Hidden Files 等）
│   ├── HiddenFileActions.swift   # 文件隐藏/取消隐藏操作
│   ├── ImageActions.swift        # 图像处理（ICNS, iOS/Mac Icons, Custom Icon）
│   ├── ServiceActions.swift      # 在线服务（翻译, QR Code）
│   ├── iShotActions.swift        # iShot 集成（截图, 标注）
│   └── OpenPreferencesAction.swift
├── UI/
│   ├── StatusBarController.swift # 状态栏图标与右键菜单
│   └── PreferencesWindowController.swift  # 偏好设置窗口（6 标签页）
└── Utils/
    ├── PasteboardReader.swift    # 从 NSPasteboard 提取文件路径
    ├── FileHasher.swift          # 文件哈希计算（MD5, SHA1, SHA256, SHA512）
    ├── QRCodeGenerator.swift     # 二维码生成
    ├── TranslationHelper.swift   # 翻译服务（百度, Google）
    ├── AirDropHelper.swift       # AirDrop 分享辅助
    ├── ImageConverter.swift      # 图片格式转换（ICNS, iOS/Mac iconset）
    └── IconSetter.swift          # 自定义图标设置

mac-right-helperTests/            # XCTest 测试目标
├── ConfigManagerTests.swift
├── PasteboardReaderTests.swift
├── ScriptExecutorTests.swift
├── PermissionManagerTests.swift
├── ActionDispatcherTests.swift
├── CustomScriptHandlerTests.swift
└── OpenPreferencesActionTests.swift
```

### 架构设计

**核心设计原则**

**`Actions/` 中的 Handler 是纯值类型。** 所有内置的 `ActionHandler` 实现都应为 `struct`。它们接收文件路径，通过 `ScriptExecutor` 或 API 执行任务，不持有任何可变共享状态。

**`ActionDispatcher` 是唯一分发点。** 它将 `userData`（操作 ID）解析为静态内置注册表中的 Handler，或在运行时构造 `CustomScriptHandler`。支持三种动态操作：模板文件创建（`tpl_*`）、发送到收藏文件夹（`fav_*`）、收藏目录跳转（`dir_*`）。所有错误统一在主线程通过 `NSAlert` 展示。

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
- **`ScriptExecutor`** — 异步 Shell / Python / AppleScript 执行器
- **`PasteboardReader`** — 从 `NSPasteboard` 提取文件路径
- **`AppConfig`** — 配置根模型，包含 `builtinItems`、`customScripts`、`templates`、`favoriteFolders`、`favoriteDirectories`、`settings`
- **`EditorConfig`** — 支持的编辑器列表（bundleID 驱动，通过 `open -b` 启动）

### 添加新的内置操作

新增内置操作需要完成以下四步：

1. **实现 Handler**：在合适的 `Actions/*.swift` 文件中实现 `ActionHandler` 协议

   ```swift
   struct MyAction: ActionHandler {
       func handle(filePaths: [String]) async throws {
           guard !filePaths.isEmpty else { return }
           // 执行操作...
       }
   }
   ```

2. **注册到分发器**：在 `ActionDispatcher.handlers` 注册表中添加该操作

   ```swift
   "myAction": MyAction()
   ```

3. **注册到默认配置**：在 `AppConfig.defaultConfig.builtinItems` 中添加该操作，指定默认启用状态、权重（控制菜单排序）和分组

   ```swift
   "myAction": BuiltinItemConfig(enabled: true, weight: 150, group: "Dev")
   ```

4. **声明服务**：在 `Info.plist` 的 `NSServices` 数组下添加对应的 `<dict>` 条目，`NSUserData` 的值必须与注册表中的 Key 完全一致

5. **编写单元测试**：覆盖空输入、正常输入和错误路径

6. **运行测试验证**：

   ```bash
   xcodebuild test -scheme mac-right-helper -destination 'platform=macOS'
   ```

### 开发规则

1. **ActionHandler 必须是值类型**：所有内置 Handler 都应使用 `struct`，Handler 调用之间不共享可变状态
2. **错误必须通过 ActionDispatcher 展示**：Handler 内部不得直接显示 `NSAlert`，应抛出错误由分发器统一处理
3. **空输入静默返回**：在 `handle(filePaths:)` 内部使用 `guard` 对空输入直接返回，不抛异常
4. **UI 操作必须在主线程**：`NSAlert`、`NSOpenPanel` 等 UI 操作必须通过 `await MainActor.run` 执行
5. **新操作三步注册**：Handler 实现 → `ActionDispatcher.handlers` → `Info.plist`，缺一不可

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

测试模式：
- `ActionHandler` 实现至少覆盖：空输入、正常输入、错误路径
- `ActionDispatcher` 至少覆盖：内置操作解析、自定义脚本解析、未知操作返回 `nil`
- `ScriptExecutor` 至少覆盖：Shell / Python / AppleScript 成功执行、Shell 失败抛出
- `ConfigManager` 至少覆盖：默认配置加载、保存与重新加载、自定义脚本往返
- 对 `async throws` API 使用 `async` 测试方法；对期望抛出异常的路径使用 `do/try/catch` + `XCTFail`

### 构建

```bash
# Release 构建（自动检测 Xcode 或回退到独立打包）
./build.sh

# Release 构建（通过 xcodebuild）
xcodebuild -scheme mac-right-helper -destination 'platform=macOS' -configuration Release build
```

**注意：** `.xcodeproj` 不在本仓库中跟踪。构建脚本假设本地 Xcode 项目中存在一个名为 `mac-right-helper` 的 scheme。

---

## 技术细节

- 应用以 `LSUIElement` 后台代理运行，**无 Dock 图标**
- Finder 集成完全依赖 `Info.plist` 中的 `NSServices` 声明，无需独立的 Finder Sync Extension
- 使用 `NSUpdateDynamicServices()` 在运行时热重载服务列表，配置更改后无需重启应用
- 所有操作均为异步执行（`async throws`），错误通过 `NSAlert` 在主线程统一展示
- `ActionHandler` 全部采用无状态的 `struct` 实现，避免共享可变状态
- `Core/` 模块不依赖 `Actions/` 或 `UI/`，保持底层能力的独立性
- 编辑器支持通过 `open -b <bundleID>` 通用启动，可扩展
- `build.sh` 在无 Xcode 环境下生成的二进制为 Universal Binary（`arm64` + `x86_64`），同时支持 Apple Silicon 和 Intel Mac
- 配置模型使用 `Codable`，序列化到 `UserDefaults`，支持版本迁移

---

## 权限说明

| 权限 | 用途 |
|------|------|
| **完全磁盘访问权限** | 访问用户目录下的文件以执行复制、移动、压缩、解压、删除、哈希计算等操作 |
| **辅助功能** | 部分系统级操作需要（如切换隐藏文件、更改文件权限） |

首次启动时若未授权，应用会弹出提示并引导至系统设置。

---

## License

MIT License
