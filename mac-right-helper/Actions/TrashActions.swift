import Foundation
import AppKit

struct TrashPermanentlyAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard !filePaths.isEmpty else { return }
        let settings = ConfigManager.shared.config.settings
        if settings.trashConfirm {
            let confirmed = await MainActor.run { () -> Bool in
                let alert = NSAlert()
                alert.messageText = "Permanently Delete?"
                alert.informativeText = "This will permanently delete \(filePaths.count) item(s). This cannot be undone."
                alert.alertStyle = .critical
                alert.addButton(withTitle: "Delete")
                alert.addButton(withTitle: "Cancel")
                return alert.runModal() == .alertFirstButtonReturn
            }
            guard confirmed else { return }
        }
        for path in filePaths {
            try FileManager.default.removeItem(atPath: path)
        }
    }
}
