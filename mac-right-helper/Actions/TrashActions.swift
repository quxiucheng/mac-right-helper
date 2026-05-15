import Foundation
import AppKit

struct TrashPermanentlyAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard !filePaths.isEmpty else { return }
        let settings = ConfigManager.shared.config.settings
        if settings.trashConfirm {
            let confirmed = await MainActor.run { () -> Bool in
                let alert = NSAlert()
                alert.messageText = L("permanentlyDelete")
                alert.informativeText = L("permanentlyDeleteInfo", arguments: filePaths.count)
                alert.alertStyle = .critical
                alert.addButton(withTitle: L("delete"))
                alert.addButton(withTitle: L("cancel"))
                return alert.runModal() == .alertFirstButtonReturn
            }
            guard confirmed else { return }
        }
        for path in filePaths {
            try FileManager.default.removeItem(atPath: path)
        }
    }
}
