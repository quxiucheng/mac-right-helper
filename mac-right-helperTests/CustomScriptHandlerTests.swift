import XCTest
@testable import mac_right_helper

final class CustomScriptHandlerTests: XCTestCase {

    func testHandleShellScript() async throws {
        let script = CustomScript(
            id: "test-shell",
            name: "Test Shell",
            type: .shell,
            source: "echo $1",
            icon: nil,
            sendTypes: ["public.item"],
            sortWeight: 1
        )
        let handler = CustomScriptHandler(script: script)
        try await handler.handle(filePaths: ["hello"])
    }

    func testHandlePythonScript() async throws {
        let script = CustomScript(
            id: "test-python",
            name: "Test Python",
            type: .python,
            source: "import sys; print(sys.argv[1])",
            icon: nil,
            sendTypes: ["public.item"],
            sortWeight: 1
        )
        let handler = CustomScriptHandler(script: script)
        try await handler.handle(filePaths: ["hello"])
    }

    func testHandleAppleScript() async throws {
        let script = CustomScript(
            id: "test-apple",
            name: "Test AppleScript",
            type: .appleScript,
            source: "return \"hello\"",
            icon: nil,
            sendTypes: ["public.item"],
            sortWeight: 1
        )
        let handler = CustomScriptHandler(script: script)
        try await handler.handle(filePaths: [])
    }

    func testHandleShellScriptFailure() async {
        let script = CustomScript(
            id: "test-fail",
            name: "Test Fail",
            type: .shell,
            source: "exit 1",
            icon: nil,
            sendTypes: ["public.item"],
            sortWeight: 1
        )
        let handler = CustomScriptHandler(script: script)
        do {
            try await handler.handle(filePaths: [])
            XCTFail("Expected shell script to throw")
        } catch {
            // expected
        }
    }
}
