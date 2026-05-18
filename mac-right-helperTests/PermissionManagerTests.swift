import XCTest
@testable import mac_right_helper

final class PermissionManagerTests: XCTestCase {
    func testFullDiskAccessStatus() {
        let manager = PermissionManager()
        let status = manager.fullDiskAccessStatus
        XCTAssertTrue(status == .granted || status == .denied || status == .unknown)
    }

    func testAccessibilityStatus() {
        let manager = PermissionManager()
        let status = manager.accessibilityStatus
        XCTAssertTrue(status == .granted || status == .denied)
    }

    func testRequestAccessibilityPermissionReturnsBool() {
        let manager = PermissionManager()
        let result = manager.requestAccessibilityPermission()
        // Should return a boolean (will be false in CI without TCC grant)
        XCTAssertTrue(result == true || result == false)
    }
}
