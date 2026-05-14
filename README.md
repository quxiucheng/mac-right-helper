# mac-right-helper

mac-right-helper 是一个 macOS Finder 右键扩展工具，通过 macOS `NSServices` 机制将常用操作注入 Finder 的"服务"菜单，让用户在右键文件/文件夹时即可执行实用功能，无需打开终端或额外应用程序。

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

## 系统要求

- **macOS 12.0 (Monterey)** 或更高版本
- 需要在**系统设置 > 隐私与安全性 > 完全磁盘访问权限**中授予应用权限
- 首次使用时需在**系统设置 > 通用 > 登录项与扩展 > 服务**中勾选本应用

---

## 安装

```bash
git clone https://github.com/yourusername/mac-right-helper.git
cd mac-right-helper
```

使用 Xcode 打开项目并构建运行，或使用命令行构建：

```bash
# Release 构建
./build.sh

# 或直接使用 xcodebuild
xcodebuild -scheme mac-right-helper -destination 'platform=macOS' -configuration Release build
```

---

## 使用说明

1. **启动应用**后，状态栏会出现一个 `hand.point.up.left` 图标
   - **左键点击**：打开偏好设置窗口
   - **右键点击**：显示菜单（偏好设置 / 重新加载服务 / 退出）

2. **在 Finder 中右键**任意文件或文件夹，选择"服务"子菜单，即可看到所有可用操作

3. **配置自定义脚本**：通过偏好设置窗口添加、排序或禁用菜单项

---

## 项目结构

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

---

## 开发

### 构建

```bash
# Release 构建
./build.sh

# Debug 构建
xcodebuild -scheme mac-right-helper -destination 'platform=macOS' build
```

### 测试

```bash
# 运行全部测试
xcodebuild test -scheme mac-right-helper -destination 'platform=macOS'

# 运行单个测试类
xcodebuild test -scheme mac-right-helper -destination 'platform=macOS' -only-testing mac-right-helperTests/ConfigManagerTests

# 运行单个测试方法
xcodebuild test -scheme mac-right-helper -destination 'platform=macOS' -only-testing mac-right-helperTests/ConfigManagerTests/testSaveAndLoadConfig
```

### 添加新的内置操作

1. 在 `Actions/FileActions.swift`、`DevActions.swift` 或 `SystemActions.swift` 中实现 `ActionHandler` 协议
2. 在 `ActionDispatcher.handlers` 中注册该操作
3. 在 `Info.plist` 的 `NSServices` 下添加对应的 `<dict>` 条目
4. 编写对应的单元测试

---

## 技术细节

- 应用以 `LSUIElement` 后台代理运行，**无 Dock 图标**
- Finder 集成完全依赖 `Info.plist` 中的 `NSServices` 声明，无需独立的 Finder Sync Extension
- 使用 `NSUpdateDynamicServices()` 在运行时热重载服务列表，配置更改后无需重启应用
- 所有操作均为异步执行，错误通过 `NSAlert` 在主线程展示

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
