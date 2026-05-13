import XCTest
@testable import mac_right_helper

final class OpenPreferencesActionTests: XCTestCase {

    func testHandleDoesNotThrow() async {
        let action = OpenPreferencesAction()
        // UI operations run on MainActor; this should complete without throwing
        await action.handle(filePaths: [])
    }

    func testHandleIgnoresFilePaths() async {
        let action = OpenPreferencesAction()
        // Should not throw even with file paths provided
        await action.handle(filePaths: ["/tmp/test.txt"])
    }
}
