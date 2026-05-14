import XCTest
@testable import mac_right_helper

final class HiddenFileActionsTests: XCTestCase {
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

    func testHideSelectedFilesEmpty() async throws {
        let action = HideSelectedFilesAction()
        try await action.handle(filePaths: [])
    }

    func testUnhideSelectedFilesEmpty() async throws {
        let action = UnhideSelectedFilesAction()
        try await action.handle(filePaths: [])
    }

    func testToggleHiddenAllFilesEmpty() async throws {
        let action = ToggleHiddenAllFilesAction()
        try await action.handle(filePaths: [])
    }
}
