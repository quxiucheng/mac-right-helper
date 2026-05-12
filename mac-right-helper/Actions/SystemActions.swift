import Foundation

struct ToggleHiddenFilesAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        let executor = ScriptExecutor()
        let result = try await executor.executeShell(script: "defaults read com.apple.finder AppleShowAllFiles", arguments: [])
        let current = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        let newValue = current == "1" ? "false" : "true"
        _ = try await executor.executeShell(script: "defaults write com.apple.finder AppleShowAllFiles -bool \(newValue) && killall Finder", arguments: [])
    }
}

struct ChangePermissionsAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard let path = filePaths.first else { return }
        let executor = ScriptExecutor()
        _ = try await executor.executeShell(script: "chmod +x \"$1\"", arguments: [path])
    }
}

struct CreateSymlinkAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard filePaths.count >= 2 else { return }
        let target = filePaths[0]
        let link = filePaths[1]
        try FileManager.default.createSymbolicLink(atPath: link, withDestinationPath: target)
    }
}

struct OpenParentDirectoryAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard let path = filePaths.first else { return }
        let parent = URL(fileURLWithPath: path).deletingLastPathComponent().path
        let executor = ScriptExecutor()
        _ = try await executor.executeShell(script: "open \"$1\"", arguments: [parent])
    }
}
