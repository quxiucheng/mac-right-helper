import XCTest
@testable import mac_right_helper

final class ActionDispatcherTests: XCTestCase {

    func testHandlerForBuiltInAction() {
        let handler = ActionDispatcher.handler(for: "copyPath")
        XCTAssertNotNil(handler)
        XCTAssertTrue(handler is CopyPathAction)
    }

    func testHandlerForUnknownAction() {
        let handler = ActionDispatcher.handler(for: "nonExistentAction")
        XCTAssertNil(handler)
    }

    func testHandlerForCustomScript() {
        let manager = ConfigManager()
        let script = CustomScript(
            id: "test-script-1",
            name: "Test Script",
            type: .shell,
            source: "echo hello",
            icon: nil,
            sendTypes: ["public.item"],
            sortWeight: 1
        )
        manager.config.customScripts = [script]
        manager.save()

        let handler = ActionDispatcher.handler(for: "test-script-1")
        XCTAssertNotNil(handler)
        XCTAssertTrue(handler is CustomScriptHandler)

        manager.resetToDefaults()
    }

    func testDispatchWithValidAction() async {
        // copyPath with empty paths should not throw
        await ActionDispatcher.dispatch(actionID: "copyPath", filePaths: [])
    }

    func testDispatchWithInvalidAction() async {
        // unknown action should not throw, just print and return
        await ActionDispatcher.dispatch(actionID: "invalid-action-id", filePaths: ["/tmp"])
    }
}
