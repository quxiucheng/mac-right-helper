import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private(set) var mainPanelController: MainPanelController?
    private let ipc = AppExIPC.shared
    private(set) var extensionRunning = false
    private var heartbeatTimer: Timer?
    var statusItem: NSStatusItem? { statusBarController?.statusItem }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if !ConfigManager.shared.config.settings.hideStatusBarIcon {
            statusBarController = StatusBarController()
        }
        checkPermissions()

        // Setup IPC with Finder Sync Extension
        setupIPC()
        syncActionsToExtension()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(configChanged),
            name: ConfigManager.configChangedNotification,
            object: nil
        )

        // Show main panel on launch
        if statusBarController != nil {
            showMainPanel()
        }
    }

    // MARK: - Finder Sync IPC

    private func setupIPC() {
        // Extension heartbeat — confirms it is alive
        ipc.onHeartbeat { [weak self] in
            self?.extensionRunning = true
            self?.syncActionsToExtension()
            self?.mainPanelController?.refreshStatus()
            self?.heartbeatTimer?.invalidate()
            self?.heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [weak self] _ in
                self?.extensionRunning = false
                self?.mainPanelController?.refreshStatus()
            }
        }

        // Extension triggers an action on selected files
        ipc.onAction { actionID, filePaths, _ in
            Task {
                await ActionDispatcher.dispatch(actionID: actionID, filePaths: filePaths)
            }
        }
    }

    /// Send current enabled action list to Finder Sync Extension
    func syncActionsToExtension() {
        let config = ConfigManager.shared.config
        var actions: [ActionItem] = []

        for (actionID, itemConfig) in config.builtinItems where itemConfig.enabled {
            let name = L(actionID)
            let group = itemConfig.group
            let icon = iconForAction(actionID, group: group)
            actions.append(ActionItem(
                id: actionID,
                name: name,
                icon: icon,
                group: group,
                enabled: true
            ))
        }

        // Add dynamic template actions
        for tpl in config.templates {
            let id = "tpl_\(tpl.id)"
            guard config.builtinItems["newFileWithTemplate"]?.enabled != false else { continue }
            actions.append(ActionItem(
                id: id,
                name: "\(L("newFileWithTemplate")): \(tpl.name)",
                icon: "doc.badge.plus",
                group: "File",
                enabled: true
            ))
        }

        // Add dynamic favorite folder actions
        for folder in config.favoriteFolders {
            let id = "fav_\(folder.id)"
            guard config.builtinItems["sendToPicker"]?.enabled != false else { continue }
            actions.append(ActionItem(
                id: id,
                name: "\(L("sendTo")): \(folder.name)",
                icon: "folder",
                group: "File",
                enabled: true
            ))
        }

        // Add dynamic favorite directory actions
        for dir in config.favoriteDirectories {
            let id = "dir_\(dir.id)"
            guard config.builtinItems["favoriteDirPicker"]?.enabled != false else { continue }
            actions.append(ActionItem(
                id: id,
                name: "\(L("goToDirectory")): \(dir.name)",
                icon: "arrow.right.circle",
                group: "File",
                enabled: true
            ))
        }

        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let monitorDirs = [
            "/",
            homeDir,
            "\(homeDir)/Desktop",
            "\(homeDir)/Documents",
            "\(homeDir)/Downloads"
        ]

        ipc.sendConfig(actions: actions, monitorDirs: monitorDirs)
    }

    private func iconForAction(_ id: String, group: String) -> String {
        switch id {
        case "copyPath": return "doc.on.doc"
        case "copyFileName": return "pencil"
        case "newFile": return "doc.badge.plus"
        case "newFileWithTemplate": return "doc.text"
        case "newFolderFromFileName": return "folder.badge.plus"
        case "compress": return "archivebox"
        case "decompress": return "archivebox.fill"
        case "moveTo": return "arrow.right.doc.on.clipboard"
        case "copyTo": return "doc.on.clipboard"
        case "cutFiles": return "scissors"
        case "sendToPicker": return "paperplane"
        case "sendAliasToDesktop": return "desktopcomputer"
        case "trashPermanently": return "trash"
        case "favoriteDirPicker": return "folder"
        case "showFileInfo": return "info.circle"
        case "airdrop": return "antenna.radiowaves.left.and.right"
        case "openInVSCode": return "chevron.left.forwardslash.chevron.right"
        case "openInTerminal": return "terminal"
        case "openInITerm2": return "terminal.fill"
        case "openInSublimeText": return "curlybraces"
        case "openInWarp": return "terminal"
        case "openInIDEA": return "hammer"
        case "gitInit": return "arrow.triangle.branch"
        case "gitStatus": return "arrow.triangle.pull"
        case "formatJSON": return "curlybraces"
        case "toggleHiddenFiles": return "eye"
        case "hideSelectedFiles": return "eye.slash"
        case "unhideSelectedFiles": return "eye"
        case "changePermissions": return "lock.shield"
        case "createSymlink": return "link"
        case "openParentDirectory": return "arrow.up.forward.app"
        case "imageToICNS": return "photo"
        case "imageToIOSIcons": return "apps.iphone"
        case "imageToMacIcons": return "macwindow"
        case "setCustomIcon": return "paintbrush"
        case "translateBaidu": return "character.bubble"
        case "translateGoogle": return "globe"
        case "toQRCode": return "qrcode"
        case "iShotScreenshot": return "camera.viewfinder"
        case "iShotAnnotate": return "pencil.tip.crop.circle"
        case "openPreferences": return "gearshape"
        default: return group == "Dev" ? "hammer" : "square"
        }
    }

    // MARK: - Settings changes

    @objc private func configChanged() {
        syncActionsToExtension()
        let shouldHide = ConfigManager.shared.config.settings.hideStatusBarIcon
        if shouldHide {
            statusBarController = nil
        } else if statusBarController == nil {
            statusBarController = StatusBarController()
            showMainPanel()
        }
    }

    // MARK: - Window management

    func showMainPanel() {
        if mainPanelController == nil {
            mainPanelController = MainPanelController()
        }
        mainPanelController?.showWindow(nil)
        mainPanelController?.refreshStatus()
        NSApp.activate(ignoringOtherApps: true)
    }

    func showPreferences() {
        statusBarController?.openPreferences()
    }

    func applicationWillTerminate(_ notification: Notification) {
        ipc.sendQuit()
    }

    // MARK: - NSServices Support

    @objc func handleRightHelperService(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        guard let urls = pboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !urls.isEmpty else {
            error.pointee = "No files selected" as NSString
            return
        }
        let paths = urls.map { $0.path }

        // Parse action ID from userData or use default
        let actionID = userData.isEmpty ? "copyPath" : userData

        Task {
            await ActionDispatcher.dispatch(actionID: actionID, filePaths: paths)
        }
    }

    // MARK: - Permissions

    func checkPermissions() {
        let manager = PermissionManager()
        let fda = manager.fullDiskAccessStatus
        let ax = manager.accessibilityStatus

        if fda != .granted {
            showPermissionAlert(
                title: L("fullDiskAccessRequired"),
                info: L("fullDiskAccessInfo"),
                url: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
            )
        }

        if ax != .granted {
            showPermissionAlert(
                title: L("accessibilityPermissionRequired"),
                info: L("accessibilityPermissionInfo"),
                url: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
            )
        }
    }

    func requestAccessibilityPermission() {
        let manager = PermissionManager()
        manager.requestAccessibilityPermission()
        mainPanelController?.refreshStatus()
    }

    func showPermissionAlert(title: String, info: String, url: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = info
        alert.alertStyle = .warning
        alert.addButton(withTitle: L("openSettings"))
        alert.addButton(withTitle: L("later"))
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let url = URL(string: url) {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
