import AppKit

struct OpenPreferencesAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        await MainActor.run {
            let controller = PreferencesWindowController()
            controller.showWindow(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
