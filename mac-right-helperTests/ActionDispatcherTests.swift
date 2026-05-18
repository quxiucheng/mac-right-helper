import XCTest
@testable import mac_right_helper

final class ActionDispatcherTests: XCTestCase {
    private let manager = ConfigManager.shared

    override func setUp() {
        super.setUp()
        manager.resetToDefaults()
    }

    override func tearDown() {
        manager.resetToDefaults()
        super.tearDown()
    }

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
    }

    func testDispatchWithValidAction() async {
        await ActionDispatcher.dispatch(actionID: "copyPath", filePaths: [])
    }

    func testDispatchWithInvalidAction() async {
        await ActionDispatcher.dispatch(actionID: "invalid-action-id", filePaths: ["/tmp"])
    }

    func testDisabledBuiltInActionReturnsNil() {
        manager.config.builtinItems["copyPath"] = AppConfig.BuiltinItemConfig(enabled: false, weight: 10, group: "File")
        manager.save()

        let handler = ActionDispatcher.handler(for: "copyPath")
        XCTAssertNil(handler)
    }

    func testEnabledBuiltInActionReturnsHandler() {
        let handler = ActionDispatcher.handler(for: "copyPath")
        XCTAssertNotNil(handler)
        XCTAssertTrue(handler is CopyPathAction)
    }

    func testNewBuiltInHandlersExist() {
        XCTAssertNotNil(ActionDispatcher.handler(for: "trashPermanently"))
        XCTAssertNotNil(ActionDispatcher.handler(for: "showFileInfo"))
        XCTAssertNotNil(ActionDispatcher.handler(for: "airdrop"))
        XCTAssertNotNil(ActionDispatcher.handler(for: "translateBaidu"))
        XCTAssertNotNil(ActionDispatcher.handler(for: "toQRCode"))
        XCTAssertNotNil(ActionDispatcher.handler(for: "iShotScreenshot"))
        XCTAssertNotNil(ActionDispatcher.handler(for: "imageToICNS"))
        XCTAssertNotNil(ActionDispatcher.handler(for: "openInITerm2"))
    }

    func testDynamicTemplateHandler() {
        manager.config.templates = [FileTemplate(id: "test-tpl", name: "Test", ext: "txt", content: "")]
        manager.save()

        let handler = ActionDispatcher.handler(for: "tpl_test-tpl")
        XCTAssertNotNil(handler)
        XCTAssertTrue(handler is NewFileWithTemplateAction)
    }

    func testDynamicFavoriteFolderHandler() {
        manager.config.favoriteFolders = [FavoriteFolder(id: "test-fav", name: "Test", path: "/tmp")]
        manager.save()

        let handler = ActionDispatcher.handler(for: "fav_test-fav")
        XCTAssertNotNil(handler)
        XCTAssertTrue(handler is SendToFolderAction)
    }

    func testDynamicFavoriteDirectoryHandler() {
        manager.config.favoriteDirectories = [FavoriteDirectory(id: "test-dir", name: "Test", path: "/tmp")]
        manager.save()

        let handler = ActionDispatcher.handler(for: "dir_test-dir")
        XCTAssertNotNil(handler)
        XCTAssertTrue(handler is OpenDirectoryAction)
    }
}
