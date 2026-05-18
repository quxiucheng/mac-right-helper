import Cocoa
import FinderSync

private let tagQueue = DispatchQueue(label: "com.example.finder-sync-ext.tags")

class FinderSyncExt: FIFinderSync {

    private var tagRidMap: [Int: String] = [:]
    private var menuActions: [ActionItem] = []
    private var isHostRunning = false
    private let ipc = AppExIPC.shared
    private var currentMenuKind: FIMenuKind = .contextualMenuForContainer

    // MARK: - Init

    override init() {
        super.init()

        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]

        // Listen for config updates from main app
        ipc.onConfig { [weak self] actions, dirs in
            self?.isHostRunning = true
            if !dirs.isEmpty {
                let urls = Set(dirs.map { URL(fileURLWithPath: $0) })
                FIFinderSyncController.default().directoryURLs = urls
            }
            if !actions.isEmpty {
                self?.menuActions = actions
            }
        }

        // Listen for quit signal from main app
        ipc.onQuit { [weak self] in
            self?.isHostRunning = false
        }

        // Send initial heartbeat
        ipc.sendHeartbeat()
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

        guard isHostRunning else {
            let item = NSMenuItem(
                title: "mac-right-helper (not running)",
                action: nil,
                keyEquivalent: ""
            )
            item.isEnabled = false
            menu.addItem(item)
            return menu
        }

        switch menuKind {
        case .contextualMenuForItems, .contextualMenuForContainer, .toolbarItemMenu:
            buildMenu(menu)
        default:
            break
        }

        return menu
    }

    private func buildMenu(_ menu: NSMenu) {
        let groups = Dictionary(grouping: menuActions.filter(\.enabled)) { $0.group }
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

        ipc.sendAction(actionID: rid, filePaths: targets, trigger: trigger)
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
        case "File": return "File"
        case "Dev": return "Dev Tools"
        case "System": return "System"
        case "Image": return "Image"
        case "Service": return "Services"
        case "iShot": return "iShot"
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
