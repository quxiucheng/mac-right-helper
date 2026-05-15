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
        XCTAssertEqual(manager.config.version, 2)
        XCTAssertTrue(manager.config.builtinItems["copyPath"]?.enabled ?? false)
        XCTAssertFalse(manager.config.settings.hideStatusBarIcon)
        XCTAssertEqual(manager.config.templates.count, 10)
        XCTAssertEqual(manager.config.favoriteDirectories.count, 4)
    }

    func testSaveAndLoadConfig() {
        let manager = ConfigManager()
        manager.config.builtinItems["copyPath"] = AppConfig.BuiltinItemConfig(enabled: false, weight: 99, group: "File")
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

    func testTemplateRoundtrip() {
        let manager = ConfigManager()
        manager.config.templates.append(FileTemplate(id: "test", name: "Test", ext: "test", content: "hello"))
        manager.save()

        let manager2 = ConfigManager()
        XCTAssertTrue(manager2.config.templates.contains(where: { $0.id == "test" }))
    }

    func testFavoriteFolderRoundtrip() {
        let manager = ConfigManager()
        manager.config.favoriteFolders = [
            FavoriteFolder(id: "test", name: "Test", path: "/tmp")
        ]
        manager.save()

        let manager2 = ConfigManager()
        XCTAssertEqual(manager2.config.favoriteFolders.count, 1)
    }

    func testSettingsRoundtrip() {
        let manager = ConfigManager()
        manager.config.settings.hideStatusBarIcon = true
        manager.config.settings.terminalOpenMode = .newTab
        manager.save()

        let manager2 = ConfigManager()
        XCTAssertTrue(manager2.config.settings.hideStatusBarIcon)
        XCTAssertEqual(manager2.config.settings.terminalOpenMode, .newTab)
    }

    func testLanguageDefault() {
        let manager = ConfigManager()
        XCTAssertEqual(manager.config.settings.language, .chinese)
    }

    func testLanguageRoundtrip() {
        let manager = ConfigManager()
        manager.config.settings.language = .english
        manager.save()

        let manager2 = ConfigManager()
        XCTAssertEqual(manager2.config.settings.language, .english)
    }
}
