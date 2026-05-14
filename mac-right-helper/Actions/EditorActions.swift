import Foundation

struct OpenInEditorAction: ActionHandler {
    let bundleID: String

    func handle(filePaths: [String]) async throws {
        guard let path = filePaths.first else { return }
        var target = path
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDir), !isDir.boolValue {
            target = URL(fileURLWithPath: path).deletingLastPathComponent().path
        }
        let executor = ScriptExecutor()
        _ = try await executor.executeShell(script: "open -b \"\(bundleID)\" \"\(target)\"", arguments: [])
    }
}

struct OpenInTerminalAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard let path = filePaths.first else { return }
        var target = path
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDir), !isDir.boolValue {
            target = URL(fileURLWithPath: path).deletingLastPathComponent().path
        }
        let executor = ScriptExecutor()
        let mode = ConfigManager.shared.config.settings.terminalOpenMode
        if mode == .newTab {
            _ = try await executor.executeShell(script: "osascript -e 'tell app \"Terminal\" to activate' -e 'tell app \"Terminal\" to do script \"cd \\\"\(target)\\\"\"'", arguments: [])
        } else {
            _ = try await executor.executeShell(script: "open -a Terminal \"\(target)\"", arguments: [])
        }
    }
}

struct OpenInITerm2Action: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard let path = filePaths.first else { return }
        var target = path
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDir), !isDir.boolValue {
            target = URL(fileURLWithPath: path).deletingLastPathComponent().path
        }
        let executor = ScriptExecutor()
        let mode = ConfigManager.shared.config.settings.terminalOpenMode
        if mode == .newTab {
            let script = """
            tell application "iTerm"
                activate
                tell current window
                    create tab with default profile
                    tell current session
                        write text "cd \"\(target)\""
                    end tell
                end tell
            end tell
            """
            _ = try await executor.executeAppleScript(source: script)
        } else {
            let script = """
            tell application "iTerm"
                activate
                create window with default profile
                tell current session of current window
                    write text "cd \"\(target)\""
                end tell
            end tell
            """
            _ = try await executor.executeAppleScript(source: script)
        }
    }
}
