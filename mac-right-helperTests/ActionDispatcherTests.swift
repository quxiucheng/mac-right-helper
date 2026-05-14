import XCTest
@testable import mac_right_helper

final class ActionDispatcherTests: XCTestCase {

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
        let manager = ConfigManager()
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

        manager.resetToDefaults()
    }

    func testDispatchWithValidAction() async {
        // copyPath with empty paths should not throw
        await ActionDispatcher.dispatch(actionID: "copyPath", filePaths: [])
    }

    func testDispatchWithInvalidAction() async {
        // unknown action should not throw, just print and return
        await ActionDispatcher.dispatch(actionID: "invalid-action-id", filePaths: ["/tmp"])
    }

    func testDisabledBuiltInActionReturnsNil() {
        let manager = ConfigManager()
        manager.config.builtinItems["copyPath"] = AppConfig.BuiltinItemConfig(enabled: false, weight: 10, group: "File")
        manager.save()

        let handler = ActionDispatcher.handler(for: "copyPath")
        XCTAssertNil(handler)

        manager.resetToDefaults()
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
        let manager = ConfigManager()
        manager.config.templates = [FileTemplate(id: "test-tpl", name: "Test", ext: "txt", content: "")]
        manager.save()

        let handler = ActionDispatcher.handler(for: "tpl_test-tpl")
        XCTAssertNotNil(handler)
        XCTAssertTrue(handler is NewFileWithTemplateAction)

        manager.resetToDefaults()
    }

    func testDynamicFavoriteFolderHandler() {
        let manager = ConfigManager()
        manager.config.favoriteFolders = [FavoriteFolder(id: "test-fav", name: "Test", path: "/tmp")]
        manager.save()

        let handler = ActionDispatcher.handler(for: "fav_test-fav")
        XCTAssertNotNil(handler)
        XCTAssertTrue(handler is SendToFolderAction)

        manager.resetToDefaults()
    }

    func testDynamicFavoriteDirectoryHandler() {
        let manager = ConfigManager()
        manager.config.favoriteDirectories = [FavoriteDirectory(id: "test-dir", name: "Test", path: "/tmp")]
        manager.save()

        let handler = ActionDispatcher.handler(for: "dir_test-dir")
        XCTAssertNotNil(handler)
        XCTAssertTrue(handler is OpenDirectoryAction)

        manager.resetToDefaults()
    }
}
