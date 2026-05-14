import XCTest
@testable import mac_right_helper

final class TrashActionsTests: XCTestCase {
    private var testDir: String!
    private var testFile: String!

    override func setUp() {
        super.setUp()
        testDir = "/tmp/mac-right-helper-test-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(atPath: testDir, withIntermediateDirectories: true)
        testFile = (testDir as NSString).appendingPathComponent("test.txt")
        FileManager.default.createFile(atPath: testFile, contents: "hello".data(using: .utf8))
    }

    override func tearDown() {
        try? FileManager.default.removeItem(atPath: testDir)
        super.tearDown()
    }

    func testTrashPermanentlyEmpty() async throws {
        let action = TrashPermanentlyAction()
        try await action.handle(filePaths: [])
    }

    func testTrashPermanentlyWithoutConfirm() async throws {
        let manager = ConfigManager()
        manager.config.settings.trashConfirm = false
        manager.save()

        let action = TrashPermanentlyAction()
        try await action.handle(filePaths: [testFile])
        XCTAssertFalse(FileManager.default.fileExists(atPath: testFile))

        manager.resetToDefaults()
    }
}
