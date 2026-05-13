import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController()
        checkPermissions()
        NSUpdateDynamicServices()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(configChanged),
            name: ConfigManager.configChangedNotification,
            object: nil
        )
    }

    func handleService(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        let paths = PasteboardReader.extractFilePaths(from: pboard)
        Task {
            await ActionDispatcher.dispatch(actionID: userData, filePaths: paths)
        }
    }

    @objc private func configChanged() {
        NSUpdateDynamicServices()
    }

    private func checkPermissions() {
        let manager = PermissionManager()
        if manager.fullDiskAccessStatus != .granted {
            showPermissionAlert(title: "Full Disk Access Required",
                                info: "mac-right-helper needs Full Disk Access to operate on files in protected locations. Please enable it in System Settings.",
                                url: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")
        }
    }

    private func showPermissionAlert(title: String, info: String, url: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = info
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Later")
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let url = URL(string: url) {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
