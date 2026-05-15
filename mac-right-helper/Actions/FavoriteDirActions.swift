import Foundation
import AppKit

struct FavoriteDirPickerAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        let dirs = ConfigManager.shared.config.favoriteDirectories
        guard !dirs.isEmpty else { return }

        let dest = await MainActor.run { () -> FavoriteDirectory? in
            let alert = NSAlert()
            alert.messageText = L("goToDirectory")
            alert.informativeText = L("chooseDirectory")
            for dir in dirs {
                alert.addButton(withTitle: dir.name)
            }
            alert.addButton(withTitle: L("cancel"))
            let response = alert.runModal()
            let index = response.rawValue - NSApplication.ModalResponse.alertFirstButtonReturn.rawValue
            if index >= 0 && index < dirs.count {
                return dirs[index]
            }
            return nil
        }

        guard let dest = dest else { return }
        let path = dest.path.replacingOccurrences(of: "~", with: FileManager.default.homeDirectoryForCurrentUser.path)
        NSWorkspace.shared.open(URL(fileURLWithPath: path))
    }
}
