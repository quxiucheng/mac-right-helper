import Foundation
import AppKit

struct SendToPickerAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard !filePaths.isEmpty else { return }
        let folders = ConfigManager.shared.config.favoriteFolders
        guard !folders.isEmpty else {
            await MainActor.run {
                let alert = NSAlert()
                alert.messageText = "No Favorite Folders"
                alert.informativeText = "Please add favorite folders in Preferences first."
                alert.alertStyle = .informational
                alert.runModal()
            }
            return
        }

        let dest = await MainActor.run { () -> FavoriteFolder? in
            let alert = NSAlert()
            alert.messageText = "Send to"
            alert.informativeText = "Choose a destination folder:"
            for folder in folders {
                alert.addButton(withTitle: folder.name)
            }
            alert.addButton(withTitle: "Cancel")
            let response = alert.runModal()
            let index = response.rawValue - NSApplication.ModalResponse.alertFirstButtonReturn.rawValue
            if index >= 0 && index < folders.count {
                return folders[index]
            }
            return nil
        }

        guard let dest = dest else { return }
        let destURL = URL(fileURLWithPath: dest.path.expandingTilde())
        for path in filePaths {
            let name = URL(fileURLWithPath: path).lastPathComponent
            let destPath = destURL.appendingPathComponent(name).path
            try FileManager.default.copyItem(atPath: path, toPath: destPath)
        }
    }
}

struct SendAliasToDesktopAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard !filePaths.isEmpty else { return }
        let desktop = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop").path
        for path in filePaths {
            let name = URL(fileURLWithPath: path).lastPathComponent
            let aliasPath = (desktop as NSString).appendingPathComponent("\(name) alias")
            let executor = ScriptExecutor()
            _ = try await executor.executeShell(script: "osascript -e 'tell app \"Finder\" to make alias file to POSIX file \"\(path)\" at POSIX file \"\(desktop)\"'", arguments: [])
        }
    }
}

private extension String {
    func expandingTilde() -> String {
        return self.replacingOccurrences(of: "~", with: FileManager.default.homeDirectoryForCurrentUser.path)
    }
}
