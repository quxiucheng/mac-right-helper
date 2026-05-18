import AppKit

struct OpenPreferencesAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        await MainActor.run {
            (NSApp.delegate as? AppDelegate)?.showPreferences()
        }
    }
}
