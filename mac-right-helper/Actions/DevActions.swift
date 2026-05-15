import Foundation

struct OpenInVSCodeAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard let path = filePaths.first else { return }
        let executor = ScriptExecutor()
        _ = try await executor.executeShell(script: "open -a \"Visual Studio Code\" \"$1\"", arguments: [path])
    }
}

struct GitInitAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard let path = filePaths.first else { return }
        var dir = path
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDir), !isDir.boolValue {
            dir = URL(fileURLWithPath: path).deletingLastPathComponent().path
        }
        let executor = ScriptExecutor()
        _ = try await executor.executeShell(script: "cd \"$1\" && git init", arguments: [dir])
    }
}

struct GitStatusAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard let path = filePaths.first else { return }
        var dir = path
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDir), !isDir.boolValue {
            dir = URL(fileURLWithPath: path).deletingLastPathComponent().path
        }
        let executor = ScriptExecutor()
        _ = try await executor.executeShell(script: "cd \"$1\" && open -a Terminal", arguments: [dir])
    }
}

struct FormatJSONAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard let path = filePaths.first else { return }
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let json = try JSONSerialization.jsonObject(with: data)
        let pretty = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        try pretty.write(to: URL(fileURLWithPath: path))
    }
}
