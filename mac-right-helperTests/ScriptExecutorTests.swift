import XCTest
@testable import mac_right_helper

final class ScriptExecutorTests: XCTestCase {
    func testExecuteShellEcho() async throws {
        let executor = ScriptExecutor()
        let result = try await executor.executeShell(script: "echo hello", arguments: [])
        XCTAssertTrue(result.stdout.trimmingCharacters(in: .whitespacesAndNewlines).contains("hello"))
    }

    func testExecuteShellWithArguments() async throws {
        let executor = ScriptExecutor()
        let result = try await executor.executeShell(script: "echo \"$1\"", arguments: ["/tmp/test"])
        XCTAssertTrue(result.stdout.contains("/tmp/test"))
    }

    func testExecuteShellFailure() async {
        let executor = ScriptExecutor()
        do {
            _ = try await executor.executeShell(script: "exit 1", arguments: [])
            XCTFail("Should have thrown")
        } catch {
            // expected
        }
    }
}
