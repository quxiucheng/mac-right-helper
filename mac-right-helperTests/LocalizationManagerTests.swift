import XCTest
@testable import mac_right_helper

final class LocalizationManagerTests: XCTestCase {
    private var originalLanguage: AppLanguage!

    override func setUp() {
        super.setUp()
        originalLanguage = ConfigManager.shared.config.settings.language
    }

    override func tearDown() {
        ConfigManager.shared.config.settings.language = originalLanguage
        ConfigManager.shared.save()
        super.tearDown()
    }

    // MARK: - Chinese (default)

    func testChineseAppName() {
        ConfigManager.shared.config.settings.language = .chinese
        XCTAssertEqual(L("appName"), "右键助手")
    }

    func testChinesePreferences() {
        ConfigManager.shared.config.settings.language = .chinese
        XCTAssertEqual(L("preferences"), "偏好设置")
    }

    func testChineseQuit() {
        ConfigManager.shared.config.settings.language = .chinese
        XCTAssertEqual(L("quit"), "退出")
    }

    func testChineseActionFailed() {
        ConfigManager.shared.config.settings.language = .chinese
        XCTAssertEqual(L("actionFailed"), "操作失败")
    }

    func testChineseDelete() {
        ConfigManager.shared.config.settings.language = .chinese
        XCTAssertEqual(L("delete"), "删除")
    }

    func testChineseCancel() {
        ConfigManager.shared.config.settings.language = .chinese
        XCTAssertEqual(L("cancel"), "取消")
    }

    // MARK: - English

    func testEnglishAppName() {
        ConfigManager.shared.config.settings.language = .english
        XCTAssertEqual(L("appName"), "Right Click Helper")
    }

    func testEnglishPreferences() {
        ConfigManager.shared.config.settings.language = .english
        XCTAssertEqual(L("preferences"), "Preferences")
    }

    func testEnglishQuit() {
        ConfigManager.shared.config.settings.language = .english
        XCTAssertEqual(L("quit"), "Quit")
    }

    func testEnglishActionFailed() {
        ConfigManager.shared.config.settings.language = .english
        XCTAssertEqual(L("actionFailed"), "Action Failed")
    }

    func testEnglishFileInformation() {
        ConfigManager.shared.config.settings.language = .english
        XCTAssertEqual(L("fileInformation"), "File Information")
    }

    func testEnglishIShotNotInstalled() {
        ConfigManager.shared.config.settings.language = .english
        XCTAssertEqual(L("iShotNotInstalled"), "iShot Not Installed")
    }

    // MARK: - Formatted strings

    func testPermanentlyDeleteInfoChinese() {
        ConfigManager.shared.config.settings.language = .chinese
        let result = L("permanentlyDeleteInfo", arguments: 3)
        XCTAssertTrue(result.contains("3"))
        XCTAssertTrue(result.contains("撤销"))
    }

    func testPermanentlyDeleteInfoEnglish() {
        ConfigManager.shared.config.settings.language = .english
        let result = L("permanentlyDeleteInfo", arguments: 5)
        XCTAssertTrue(result.contains("5"))
        XCTAssertTrue(result.contains("cannot be undone"))
    }

    // MARK: - Missing key falls back to Chinese

    func testMissingKeyFallsBackToChinese() {
        ConfigManager.shared.config.settings.language = .english
        let result = L("nonexistent_key")
        XCTAssertEqual(result, "nonexistent_key")
    }

    // MARK: - L() global function

    func testGlobalLFunction() {
        ConfigManager.shared.config.settings.language = .chinese
        XCTAssertEqual(L("ok"), "确定")
    }
}
