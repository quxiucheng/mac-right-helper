import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController()
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
}
