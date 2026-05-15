import Cocoa
import CoreServices

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Force register app with Launch Services so NSServices in Info.plist
        // are discovered and appear in Finder's right-click menu
        if let bundleURL = Bundle.main.bundleURL as URL? {
            LSRegisterURL(bundleURL as CFURL, true)
        }
        NSUpdateDynamicServices()

        if !ConfigManager.shared.config.settings.hideStatusBarIcon {
            statusBarController = StatusBarController()
        }
        checkPermissions()

        // Register app as services provider so Finder right-click menu works
        NSApp.servicesProvider = self

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(configChanged),
            name: ConfigManager.configChangedNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsChanged),
            name: ConfigManager.configChangedNotification,
            object: nil
        )

        // Show preferences window on launch
        if let sc = statusBarController {
            sc.showPreferences()
        }
    }

    @objc private func settingsChanged() {
        let shouldHide = ConfigManager.shared.config.settings.hideStatusBarIcon
        if shouldHide {
            statusBarController = nil
        } else if statusBarController == nil {
            statusBarController = StatusBarController()
            statusBarController?.showPreferences()
        }
    }

    @objc func handleService(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
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
            showPermissionAlert(
                title: L("fullDiskAccessRequired"),
                info: L("fullDiskAccessInfo"),
                url: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
            )
        }
    }

    private func showPermissionAlert(title: String, info: String, url: String) {
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
