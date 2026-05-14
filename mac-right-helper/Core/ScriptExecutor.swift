import Foundation
import AppKit

enum ScriptExecutionError: Error {
    case executionFailed(stderr: String, code: Int32)
    case invalidScriptType
}

struct ScriptResult {
    let stdout: String
    let stderr: String
    let exitCode: Int32
}

class ScriptExecutor {
    func executeShell(script: String, arguments: [String]) async throws -> ScriptResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", script] + arguments

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        return try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { proc in
                let stdout = self.read(pipe: stdoutPipe)
                let stderr = self.read(pipe: stderrPipe)
                if proc.terminationStatus == 0 {
                    continuation.resume(returning: ScriptResult(stdout: stdout, stderr: stderr, exitCode: proc.terminationStatus))
                } else {
                    continuation.resume(throwing: ScriptExecutionError.executionFailed(stderr: stderr, code: proc.terminationStatus))
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func executePython(script: String, arguments: [String]) async throws -> ScriptResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = ["-c", script] + arguments

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        return try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { proc in
                let stdout = self.read(pipe: stdoutPipe)
                let stderr = self.read(pipe: stderrPipe)
                if proc.terminationStatus == 0 {
                    continuation.resume(returning: ScriptResult(stdout: stdout, stderr: stderr, exitCode: proc.terminationStatus))
                } else {
                    continuation.resume(throwing: ScriptExecutionError.executionFailed(stderr: stderr, code: proc.terminationStatus))
                }
            }
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func executeAppleScript(source: String) async throws -> ScriptResult {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var errorInfo: NSDictionary?
                guard let appleScript = NSAppleScript(source: source) else {
                    continuation.resume(throwing: ScriptExecutionError.invalidScriptType)
                    return
                }
                let result = appleScript.executeAndReturnError(&errorInfo)
                if let error = errorInfo {
                    let message = error["NSAppleScriptErrorMessage"] as? String ?? "Unknown AppleScript error"
                    continuation.resume(throwing: ScriptExecutionError.executionFailed(stderr: message, code: 1))
                } else {
                    let output = result.stringValue ?? ""
                    continuation.resume(returning: ScriptResult(stdout: output, stderr: "", exitCode: 0))
                }
            }
        }
    }

    private func read(pipe: Pipe) -> String {
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
