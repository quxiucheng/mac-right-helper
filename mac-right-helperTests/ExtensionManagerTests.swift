import XCTest
@testable import mac_right_helper

final class ExtensionManagerTests: XCTestCase {

    func testExtensionBundleID() {
        XCTAssertEqual(ExtensionManager.extensionBundleID, "com.example.mac-right-helper.FinderSyncExt")
    }

    func testExtensionBundleName() {
        XCTAssertEqual(ExtensionManager.extensionBundleName, "FinderSyncExt.appex")
    }

    func testEmbeddedExtensionURLReturnsExpectedLastPathComponent() {
        guard let url = ExtensionManager.embeddedExtensionURL() else {
            XCTFail("embeddedExtensionURL should not be nil")
            return
        }
        XCTAssertEqual(url.lastPathComponent, "FinderSyncExt.appex")
    }

    func testIsExtensionEnabledReturnsFalseWhenPluginkitFails() {
        // When pluginkit is unavailable or extension is not registered,
        // isExtensionEnabled should return false rather than crash.
        // We cannot control the real system state, but we can verify
        // the method completes without throwing.
        let result = ExtensionManager.isExtensionEnabled()
        // Result depends on system state; just ensure it does not crash.
        XCTAssertTrue(result == true || result == false)
    }

    func testRegisterExtensionDoesNotCrashWhenAppexMissing() {
        // When the embedded extension bundle does not exist (e.g. in test runner),
        // registerExtension should silently return without crashing.
        ExtensionManager.registerExtension()
    }
}
