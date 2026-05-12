import Foundation
import AppKit

protocol ActionHandler {
    func handle(filePaths: [String]) async throws
}

enum ActionDispatcher {
    private static var handlers: [String: ActionHandler] = [
        "copyPath": CopyPathAction(),
        "copyFileName": CopyFileNameAction(),
        "newFile": NewFileAction(),
        "compress": CompressAction(),
        "decompress": DecompressAction(),
        "moveTo": MoveToAction(),
        "copyTo": CopyToAction(),
        "openInVSCode": OpenInVSCodeAction(),
        "openInTerminal": OpenInTerminalAction(),
        "gitInit": GitInitAction(),
        "gitStatus": GitStatusAction(),
        "formatJSON": FormatJSONAction(),
        "toggleHiddenFiles": ToggleHiddenFilesAction(),
        "changePermissions": ChangePermissionsAction(),
        "createSymlink": CreateSymlinkAction(),
        "openParentDirectory": OpenParentDirectoryAction(),
    ]

    static func handler(for actionID: String) -> ActionHandler? {
        return handlers[actionID]
    }

    static func dispatch(actionID: String, filePaths: [String]) async {
        guard let handler = handlers[actionID] else {
            print("No handler for action: \(actionID)")
            return
        }
        do {
            try await handler.handle(filePaths: filePaths)
        } catch {
            await MainActor.run {
                let alert = NSAlert()
                alert.messageText = "Action Failed"
                alert.informativeText = error.localizedDescription
                alert.alertStyle = .warning
                alert.runModal()
            }
        }
    }
}
