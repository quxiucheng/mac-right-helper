import Foundation

class LocalizationManager {
    static let shared = LocalizationManager()

    var language: AppLanguage {
        get { ConfigManager.shared.config.settings.language }
        set {
            ConfigManager.shared.config.settings.language = newValue
            ConfigManager.shared.save()
        }
    }

    private let strings: [String: [AppLanguage: String]] = [
        // General
        "appName": [.chinese: "右键助手", .english: "Right Click Helper"],
        "preferences": [.chinese: "偏好设置", .english: "Preferences"],
        "reloadServices": [.chinese: "重载服务", .english: "Reload Services"],
        "quit": [.chinese: "退出", .english: "Quit"],

        // General Tab
        "generalTab": [.chinese: "通用设置", .english: "General"],
        "appearanceSection": [.chinese: "外观", .english: "Appearance"],
        "fileOperationsSection": [.chinese: "文件操作", .english: "File Operations"],
        "terminalEditorSection": [.chinese: "终端与编辑器", .english: "Terminal & Editor"],
        "languageSection": [.chinese: "语言", .english: "Language"],
        "hideStatusBarIcon": [.chinese: "隐藏菜单栏图标", .english: "Hide status bar icon"],
        "trashConfirmation": [.chinese: "删除确认：", .english: "Trash confirmation:"],
        "trashConfirmDesc": [.chinese: "永久删除前显示确认", .english: "Show confirmation before permanently deleting"],
        "cutBehavior": [.chinese: "剪切行为：", .english: "Cut behavior:"],
        "cutHideDesc": [.chinese: "剪切后隐藏文件", .english: "Hide files after cutting"],
        "terminalOpenMode": [.chinese: "终端打开方式：", .english: "Terminal open mode:"],
        "newWindow": [.chinese: "新窗口", .english: "New Window"],
        "newTab": [.chinese: "新标签", .english: "New Tab"],
        "defaultEditor": [.chinese: "默认编辑器：", .english: "Default editor:"],
        "languageLabel": [.chinese: "语言：", .english: "Language:"],

        // Actions Tab
        "actionsTab": [.chinese: "管理功能", .english: "Manage Features"],
        "builtinActions": [.chinese: "内置功能列表", .english: "Feature List"],
        "enabled": [.chinese: "启用", .english: "Enabled"],
        "name": [.chinese: "名称", .english: "Name"],
        "group": [.chinese: "分组", .english: "Group"],

        // Templates Tab
        "templatesTab": [.chinese: "文件模板", .english: "File Templates"],
        "extensionLabel": [.chinese: "扩展名", .english: "Extension"],
        "content": [.chinese: "内容", .english: "Content"],
        "add": [.chinese: "添加", .english: "Add"],
        "remove": [.chinese: "删除", .english: "Remove"],

        // Folders Tab
        "foldersTab": [.chinese: "发送到文件夹", .english: "Send to Folders"],
        "favoriteFolders": [.chinese: "常用文件夹", .english: "Favorite Folders"],
        "path": [.chinese: "路径", .english: "Path"],

        // Directories Tab
        "directoriesTab": [.chinese: "常用目录", .english: "Favorite Directories"],
        "favoriteDirectories": [.chinese: "常用目录列表", .english: "Directory List"],

        // Scripts Tab
        "scriptsTab": [.chinese: "自定义脚本", .english: "Custom Scripts"],
        "customScripts": [.chinese: "脚本列表", .english: "Script List"],
        "type": [.chinese: "类型", .english: "Type"],
        "source": [.chinese: "源码", .english: "Source"],
        "save": [.chinese: "保存", .english: "Save"],
        "cancel": [.chinese: "取消", .english: "Cancel"],

        // Permission
        "fullDiskAccessRequired": [.chinese: "需要完全磁盘访问权限", .english: "Full Disk Access Required"],
        "fullDiskAccessInfo": [.chinese: "右键助手需要完全磁盘访问权限才能操作受保护位置的文件。请在系统设置中开启。", .english: "mac-right-helper needs Full Disk Access to operate on files in protected locations. Please enable it in System Settings."],
        "openSettings": [.chinese: "打开设置", .english: "Open Settings"],
        "later": [.chinese: "稍后", .english: "Later"],

        // Alerts
        "actionFailed": [.chinese: "操作失败", .english: "Action Failed"],
        "noFavoriteFolders": [.chinese: "没有常用文件夹", .english: "No Favorite Folders"],
        "noFavoriteFoldersInfo": [.chinese: "请先在偏好设置中添加常用文件夹。", .english: "Please add favorite folders in Preferences first."],
        "permanentlyDelete": [.chinese: "永久删除？", .english: "Permanently Delete?"],
        "permanentlyDeleteInfo": [.chinese: "这将永久删除 %d 个项目，无法撤销。", .english: "This will permanently delete %d item(s). This cannot be undone."],
        "delete": [.chinese: "删除", .english: "Delete"],
        "fileInformation": [.chinese: "文件信息", .english: "File Information"],
        "copyToClipboard": [.chinese: "复制到剪贴板", .english: "Copy to Clipboard"],
        "ok": [.chinese: "确定", .english: "OK"],
        "iShotNotInstalled": [.chinese: "未安装 iShot", .english: "iShot Not Installed"],
        "iShotNotInstalledInfo": [.chinese: "请从 App Store 安装 iShot。", .english: "Please install iShot from the App Store."],
        "restartToApply": [.chinese: "部分更改需要重启 Finder 或应用才能生效。", .english: "Some changes require restarting Finder or the app to take effect."],

        // Main Panel
        "mainPanelSubtitle": [.chinese: "右键增强，触手可及", .english: "Right-click power at your fingertips"],
        "statusSection": [.chinese: "状态", .english: "Status"],
        "finderExtensionStatus": [.chinese: "Finder 扩展：", .english: "Finder Extension:"],
        "fullDiskAccessStatus": [.chinese: "磁盘访问权限：", .english: "Full Disk Access:"],
        "accessibilityStatus": [.chinese: "辅助功能权限：", .english: "Accessibility:"],
        "enabledActionsCount": [.chinese: "已启用操作：", .english: "Enabled Actions:"],
        "connected": [.chinese: "已连接", .english: "Connected"],
        "disconnected": [.chinese: "等待连接", .english: "Waiting"],
        "granted": [.chinese: "已授权", .english: "Granted"],
        "notGranted": [.chinese: "未授权", .english: "Not Granted"],

        // Groups
        "groupFile": [.chinese: "文件", .english: "File"],
        "groupDev": [.chinese: "开发", .english: "Dev"],
        "groupSystem": [.chinese: "系统", .english: "System"],
        "groupImage": [.chinese: "图片", .english: "Image"],
        "groupService": [.chinese: "服务", .english: "Service"],
        "groupIShot": [.chinese: "iShot", .english: "iShot"],

        // Menu item names
        "copyPath": [.chinese: "拷贝路径", .english: "Copy Path"],
        "copyFileName": [.chinese: "拷贝文件名", .english: "Copy File Name"],
        "newFile": [.chinese: "新建文件", .english: "New File"],
        "newFileWithTemplate": [.chinese: "从模板新建文件", .english: "New File with Template"],
        "newFolderFromFileName": [.chinese: "根据文件名新建文件夹", .english: "New Folder from File Name"],
        "compress": [.chinese: "压缩", .english: "Compress"],
        "decompress": [.chinese: "解压", .english: "Decompress"],
        "moveTo": [.chinese: "移动到...", .english: "Move To..."],
        "copyTo": [.chinese: "复制到...", .english: "Copy To..."],
        "cutFiles": [.chinese: "剪切", .english: "Cut"],
        "sendToPicker": [.chinese: "发送到...", .english: "Send To..."],
        "sendAliasToDesktop": [.chinese: "发送快捷方式到桌面", .english: "Send Alias to Desktop"],
        "trashPermanently": [.chinese: "彻底删除", .english: "Permanently Delete"],
        "favoriteDirPicker": [.chinese: "常用目录...", .english: "Go to Directory..."],
        "showFileInfo": [.chinese: "文件信息（哈希）", .english: "File Info (Hash)"],
        "airdrop": [.chinese: "隔空投送", .english: "AirDrop"],
        "openInVSCode": [.chinese: "在 VS Code 中打开", .english: "Open in VS Code"],
        "openInTerminal": [.chinese: "在终端中打开", .english: "Open in Terminal"],
        "openInITerm2": [.chinese: "在 iTerm2 中打开", .english: "Open in iTerm2"],
        "openInSublimeText": [.chinese: "在 Sublime Text 中打开", .english: "Open in Sublime Text"],
        "openInWarp": [.chinese: "在 Warp 中打开", .english: "Open in Warp"],
        "openInIDEA": [.chinese: "在 IntelliJ IDEA 中打开", .english: "Open in IntelliJ IDEA"],
        "gitInit": [.chinese: "Git 初始化", .english: "Git Init"],
        "gitStatus": [.chinese: "Git 状态", .english: "Git Status"],
        "formatJSON": [.chinese: "格式化 JSON", .english: "Format JSON"],
        "toggleHiddenFiles": [.chinese: "切换隐藏文件显示", .english: "Toggle Hidden Files"],
        "hideSelectedFiles": [.chinese: "隐藏选中文件", .english: "Hide Selected Files"],
        "unhideSelectedFiles": [.chinese: "取消隐藏选中文件", .english: "Unhide Selected Files"],
        "changePermissions": [.chinese: "设为可执行", .english: "Make Executable"],
        "createSymlink": [.chinese: "创建符号链接", .english: "Create Symlink"],
        "openParentDirectory": [.chinese: "打开父目录", .english: "Open Parent Directory"],
        "imageToICNS": [.chinese: "转换为 ICNS", .english: "Convert to ICNS"],
        "imageToIOSIcons": [.chinese: "转换为 iOS 图标集", .english: "Convert to iOS Icon Set"],
        "imageToMacIcons": [.chinese: "转换为 Mac 图标集", .english: "Convert to Mac Icon Set"],
        "setCustomIcon": [.chinese: "设置自定义图标", .english: "Set Custom Icon"],
        "translateBaidu": [.chinese: "百度翻译", .english: "Baidu Translate"],
        "translateGoogle": [.chinese: "谷歌翻译", .english: "Google Translate"],
        "toQRCode": [.chinese: "转为二维码", .english: "Convert to QR Code"],
        "iShotScreenshot": [.chinese: "iShot 截图", .english: "iShot Screenshot"],
        "iShotAnnotate": [.chinese: "iShot 贴图标注", .english: "iShot Annotate"],
        "openPreferences": [.chinese: "右键助手偏好设置", .english: "Right Helper Preferences"],

        // SendTo / FavoriteDir picker
        "sendTo": [.chinese: "发送到", .english: "Send to"],
        "chooseDestinationFolder": [.chinese: "选择目标文件夹：", .english: "Choose a destination folder:"],
        "goToDirectory": [.chinese: "跳转到目录", .english: "Go to Directory"],
        "chooseDirectory": [.chinese: "选择要打开的目录：", .english: "Choose a directory to open:"],

        // Editor sheet
        "scriptName": [.chinese: "名称：", .english: "Name:"],
        "scriptType": [.chinese: "类型：", .english: "Type:"],
        "scriptSource": [.chinese: "源码：", .english: "Source:"],
        "templateName": [.chinese: "名称：", .english: "Name:"],
        "templateExtension": [.chinese: "扩展名：", .english: "Extension:"],
        "templateContent": [.chinese: "内容：", .english: "Content:"],
        "chooseDestination": [.chinese: "选择目标文件夹", .english: "Choose destination folder"],
        "chooseFolder": [.chinese: "选择文件夹", .english: "Choose a folder"],
        "chooseDirectoryPanel": [.chinese: "选择目录", .english: "Choose a directory"],
    ]

    func string(_ key: String) -> String {
        let currentLang = language
        if let translations = strings[key], let value = translations[currentLang] {
            return value
        }
        return strings[key]?[.chinese] ?? key
    }

    func string(_ key: String, arguments: CVarArg...) -> String {
        let format = string(key)
        return String(format: format, arguments: arguments)
    }
}

func L(_ key: String) -> String {
    return LocalizationManager.shared.string(key)
}

func L(_ key: String, arguments: CVarArg...) -> String {
    return LocalizationManager.shared.string(key, arguments: arguments)
}
