import Cocoa
import FinderSync

private let tagQueue = DispatchQueue(label: "com.example.finder-sync-ext.tags")

/// Minimal localization helper for the extension target (does not link LocalizationManager).
private func extL(_ key: String) -> String {
    let isChinese = Locale.current.languageCode?.hasPrefix("zh") ?? false
    switch key {
    case "launchHostApp": return isChinese ? "启动右键助手" : "Launch Right Click Helper"
    case "copyPath": return isChinese ? "拷贝路径" : "Copy Path"
    case "copyFileName": return isChinese ? "拷贝文件名" : "Copy File Name"
    case "openInTerminal": return isChinese ? "在终端中打开" : "Open in Terminal"
    case "openInVSCode": return isChinese ? "在 VS Code 中打开" : "Open in VS Code"
    case "compress": return isChinese ? "压缩" : "Compress"
    case "decompress": return isChinese ? "解压" : "Decompress"
    case "showFileInfo": return isChinese ? "文件信息（哈希）" : "File Info (Hash)"
    case "groupFile": return isChinese ? "文件" : "File"
    case "groupDev": return isChinese ? "开发" : "Dev"
    case "groupSystem": return isChinese ? "系统" : "System"
    case "groupImage": return isChinese ? "图片" : "Image"
    case "groupService": return isChinese ? "服务" : "Service"
    case "groupIShot": return isChinese ? "iShot" : "iShot"
    default: return key
    }
}

class FinderSyncExt: FIFinderSync {

    private var tagRidMap: [Int: String] = [:]
    private var menuActions: [ActionItem] = []
    private var currentMenuKind: FIMenuKind = .contextualMenuForContainer
    private let ipc = AppExIPC.shared

    // MARK: - Static fallback actions shown when main app is not running

    private var fallbackActions: [ActionItem] {
        [
            ActionItem(id: "copyPath", name: extL("copyPath"), icon: "doc.on.doc", group: "File", enabled: true),
            ActionItem(id: "copyFileName", name: extL("copyFileName"), icon: "pencil", group: "File", enabled: true),
            ActionItem(id: "openInTerminal", name: extL("openInTerminal"), icon: "terminal", group: "Dev", enabled: true),
            ActionItem(id: "openInVSCode", name: extL("openInVSCode"), icon: "chevron.left.forwardslash.chevron.right", group: "Dev", enabled: true),
            ActionItem(id: "compress", name: extL("compress"), icon: "archivebox", group: "File", enabled: true),
            ActionItem(id: "showFileInfo", name: extL("showFileInfo"), icon: "info.circle", group: "File", enabled: true),
        ]
    }

    // MARK: - Init

    override init() {
        super.init()
        // Do not monitor root directory; config file will supply dirs when app is running.
        FIFinderSyncController.default().directoryURLs = []
    }

    // MARK: - FIFinderSync

    override func beginObservingDirectory(at url: URL) {}
    override func endObservingDirectory(at url: URL) {}

    override var toolbarItemName: String { "RightHelper" }
    override var toolbarItemToolTip: String { "mac-right-helper quick actions" }
    override var toolbarItemImage: NSImage {
        NSImage(systemSymbolName: "hand.point.up.left", accessibilityDescription: "RightHelper")!
    }

    @MainActor
    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        currentMenuKind = menuKind
        let menu = NSMenu(title: "RightHelper")

        // Refresh config directly from shared file every time the menu is built.
        if let config = ipc.readConfig() {
            menuActions = config.actions
            if !config.monitorDirs.isEmpty {
                let urls = Set(config.monitorDirs.map { URL(fileURLWithPath: $0) })
                FIFinderSyncController.default().directoryURLs = urls
            }
        } else {
            menuActions = []
        }

        switch menuKind {
        case .contextualMenuForItems, .contextualMenuForContainer, .toolbarItemMenu:
            let isHostRunning = ipc.readConfig() != nil
            if isHostRunning {
                buildMenu(menu, from: menuActions)
            } else {
                buildFallbackMenu(menu)
            }
        default:
            break
        }

        return menu
    }

    // MARK: - Menu builders

    private func buildMenu(_ menu: NSMenu, from actions: [ActionItem]) {
        let groups = Dictionary(grouping: actions.filter(\.enabled)) { $0.group }
        let orderedGroups = ["File", "Dev", "System", "Image", "Service", "iShot"]

        for group in orderedGroups {
            guard let items = groups[group], !items.isEmpty else { continue }
            addSubmenu(menu, title: groupName(group), icon: groupIcon(group), items: items)
        }

        if let ungrouped = groups[""], !ungrouped.isEmpty {
            for item in ungrouped {
                menu.addItem(makeMenuItem(for: item))
            }
        }
    }

    private func buildFallbackMenu(_ menu: NSMenu) {
        // Launch host app
        let launchItem = NSMenuItem(
            title: extL("launchHostApp"),
            action: #selector(launchHostApp),
            keyEquivalent: ""
        )
        launchItem.target = self
        launchItem.image = NSImage(systemSymbolName: "play.circle", accessibilityDescription: nil)
        menu.addItem(launchItem)
        menu.addItem(NSMenuItem.separator())

        // Static actions
        buildMenu(menu, from: fallbackActions)
    }

    private func addSubmenu(_ menu: NSMenu, title: String, icon: String, items: [ActionItem]) {
        let parent = NSMenuItem()
        parent.title = title
        parent.image = NSImage(systemSymbolName: icon, accessibilityDescription: title)
        let submenu = NSMenu(title: title)
        for item in items {
            submenu.addItem(makeMenuItem(for: item))
        }
        parent.submenu = submenu
        menu.addItem(parent)
    }

    private func makeMenuItem(for action: ActionItem) -> NSMenuItem {
        let item = NSMenuItem()
        item.title = action.name
        item.action = #selector(executeAction(_:))
        item.target = self
        item.tag = assignTag(for: action.id)
        item.toolTip = action.name
        if !action.icon.isEmpty {
            item.image = NSImage(systemSymbolName: action.icon, accessibilityDescription: action.name)
        }
        return item
    }

    // MARK: - Tag management

    private func assignTag(for rid: String) -> Int {
        var tag = 0
        var maxAttempts = 100
        tagQueue.sync {
            repeat {
                tag = Int.random(in: 1...Int.max)
                maxAttempts -= 1
            } while tagRidMap[tag] != nil && maxAttempts > 0
            tagRidMap[tag] = rid
        }
        return tag
    }

    private func rid(for tag: Int) -> String? {
        tagQueue.sync { tagRidMap[tag] }
    }

    // MARK: - Action execution

    @MainActor
    @objc private func executeAction(_ sender: NSMenuItem) {
        guard let rid = rid(for: sender.tag) else { return }
        let targets = getSelectedPaths()
        guard !targets.isEmpty else { return }

        var trigger = "ctx-items"
        if currentMenuKind == .contextualMenuForContainer { trigger = "ctx-container" }
        else if currentMenuKind == .toolbarItemMenu { trigger = "toolbar" }

        ipc.writeAction(actionID: rid, filePaths: targets, trigger: trigger)
    }

    @MainActor
    @objc private func launchHostApp() {
        // Try to open the main app via its bundle identifier
        let bundleID = "com.example.mac-right-helper"
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
        }
    }

    private func getSelectedPaths() -> [String] {
        var paths: [String] = []

        if let urls = FIFinderSyncController.default().selectedItemURLs() {
            paths = urls.map { $0.path }
        }
        if paths.isEmpty,
           let url = FIFinderSyncController.default().targetedURL() {
            paths = [url.path]
        }
        return paths
    }

    // MARK: - Group helpers

    private func groupName(_ group: String) -> String {
        switch group {
        case "File": return extL("groupFile")
        case "Dev": return extL("groupDev")
        case "System": return extL("groupSystem")
        case "Image": return extL("groupImage")
        case "Service": return extL("groupService")
        case "iShot": return extL("groupIShot")
        default: return group
        }
    }

    private func groupIcon(_ group: String) -> String {
        switch group {
        case "File": return "doc"
        case "Dev": return "hammer"
        case "System": return "gearshape"
        case "Image": return "photo"
        case "Service": return "globe"
        case "iShot": return "camera.viewfinder"
        default: return "square"
        }
    }
}
