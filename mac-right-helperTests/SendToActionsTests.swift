import XCTest
@testable import mac_right_helper

final class SendToActionsTests: XCTestCase {
    func testSendToPickerEmpty() async throws {
        let action = SendToPickerAction()
        try await action.handle(filePaths: [])
    }

    func testSendAliasToDesktopEmpty() async throws {
        let action = SendAliasToDesktopAction()
        try await action.handle(filePaths: [])
    }
}
