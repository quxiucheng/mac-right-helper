import Foundation

struct HideSelectedFilesAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard !filePaths.isEmpty else { return }
        for path in filePaths {
            var url = URL(fileURLWithPath: path)
            var resourceValues = URLResourceValues()
            resourceValues.isHidden = true
            try url.setResourceValues(resourceValues)
        }
    }
}

struct UnhideSelectedFilesAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard !filePaths.isEmpty else { return }
        for path in filePaths {
            var url = URL(fileURLWithPath: path)
            var resourceValues = URLResourceValues()
            resourceValues.isHidden = false
            try url.setResourceValues(resourceValues)
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
