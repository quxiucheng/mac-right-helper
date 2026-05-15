import XCTest
@testable import mac_right_helper

final class StatusBarControllerTests: XCTestCase {
    func testInitializationCreatesStatusItem() {
        let controller = StatusBarController()
        XCTAssertNotNil(controller.statusItem)
        XCTAssertNotNil(controller.statusItem.button)
    }

    func testMenuItemsExist() {
        let controller = StatusBarController()
        let items = controller.menu.items
        XCTAssertEqual(items.count, 5)
        XCTAssertEqual(items[0].title, L("preferences"))
        XCTAssertEqual(items[2].title, L("reloadServices"))
        XCTAssertEqual(items[4].title, L("quit"))
    }

    func testShowPreferencesCreatesWindowController() {
        let controller = StatusBarController()
        XCTAssertNil(controller.preferencesWindowController)
        controller.showPreferences()
        XCTAssertNotNil(controller.preferencesWindowController)
    }

    func testReloadServicesDoesNotCrash() {
        let controller = StatusBarController()
        controller.reloadServices()
    }
}
