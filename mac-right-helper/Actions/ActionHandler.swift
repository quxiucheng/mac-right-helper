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
        "openPreferences": OpenPreferencesAction(),
    ]

    static func handler(for actionID: String) -> ActionHandler? {
        if let builtIn = handlers[actionID] {
            return builtIn
        }
        if let script = ConfigManager.shared.config.customScripts.first(where: { $0.id == actionID }) {
            return CustomScriptHandler(script: script)
        }
        return nil
    }

    static func dispatch(actionID: String, filePaths: [String]) async {
        guard let handler = handler(for: actionID) else {
            print("No handler for action: \(actionID)")
            return
        }
        do {
            try await handler.handle(filePaths: filePaths)
        } catch {
            await MainActor.run {
                let alert = NSAlert()
                alert.messageText = "Action Failed"
                alert.informativeText = "\(error)"
                alert.alertStyle = .warning
                alert.runModal()
            }
        }
    }
}

struct CustomScriptHandler: ActionHandler {
    let script: CustomScript

    func handle(filePaths: [String]) async throws {
        let executor = ScriptExecutor()
        switch script.type {
        case .shell:
            _ = try await executor.executeShell(script: script.source, arguments: filePaths)
        case .python:
            _ = try await executor.executePython(script: script.source, arguments: filePaths)
        case .appleScript:
            _ = try await executor.executeAppleScript(source: script.source)
        }
    }
}

struct OpenPreferencesAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        await MainActor.run {
            let controller = PreferencesWindowController()
            controller.showWindow(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
