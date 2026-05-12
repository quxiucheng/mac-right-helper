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
}
