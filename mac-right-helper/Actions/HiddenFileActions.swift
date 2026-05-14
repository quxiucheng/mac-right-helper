import Foundation

struct HideSelectedFilesAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard !filePaths.isEmpty else { return }
        for path in filePaths {
            var attrs = try FileManager.default.attributesOfItem(atPath: path)
            attrs[.posixPermissions] = 0o100000 | ((attrs[.posixPermissions] as? UInt16) ?? 0o644)
            try FileManager.default.setAttributes(attrs, ofItemAtPath: path)
        }
    }
}

struct UnhideSelectedFilesAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard !filePaths.isEmpty else { return }
        for path in filePaths {
            var attrs = try FileManager.default.attributesOfItem(atPath: path)
            attrs[.posixPermissions] = 0o644
            try FileManager.default.setAttributes(attrs, ofItemAtPath: path)
        }
    }
}

struct ToggleHiddenAllFilesAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        let executor = ScriptExecutor()
        let result = try await executor.executeShell(script: "defaults read com.apple.finder AppleShowAllFiles", arguments: [])
        let current = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        let newValue = current == "1" ? "false" : "true"
        _ = try await executor.executeShell(script: "defaults write com.apple.finder AppleShowAllFiles -bool \(newValue) && killall Finder", arguments: [])
    }
}
