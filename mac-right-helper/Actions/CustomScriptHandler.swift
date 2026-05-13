import Foundation

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
