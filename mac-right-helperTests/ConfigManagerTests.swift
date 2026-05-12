import XCTest
@testable import mac_right_helper

final class ConfigManagerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "RightHelperMenuConfig")
    }

    func testDefaultConfigLoadedWhenMissing() {
        let manager = ConfigManager()
        XCTAssertEqual(manager.config.version, 1)
        XCTAssertTrue(manager.config.builtinItems["copyPath"]?.enabled ?? false)
    }

    func testSaveAndLoadConfig() {
        let manager = ConfigManager()
        manager.config.builtinItems["copyPath"] = AppConfig.BuiltinItemConfig(enabled: false, weight: 99)
        manager.save()

        let manager2 = ConfigManager()
        XCTAssertEqual(manager2.config.builtinItems["copyPath"]?.enabled, false)
        XCTAssertEqual(manager2.config.builtinItems["copyPath"]?.weight, 99)
    }

    func testCustomScriptRoundtrip() {
        let manager = ConfigManager()
        manager.config.customScripts = [
            CustomScript(id: "test-1", name: "Test", type: .shell, source: "echo hi", icon: nil, sendTypes: ["public.item"], sortWeight: 1)
        ]
        manager.save()

        let manager2 = ConfigManager()
        XCTAssertEqual(manager2.config.customScripts.count, 1)
        XCTAssertEqual(manager2.config.customScripts.first?.name, "Test")
    }
}
