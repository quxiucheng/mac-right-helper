import XCTest
@testable import mac_right_helper

final class EditorActionsTests: XCTestCase {
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

    func testOpenInEditorEmpty() async throws {
        let action = OpenInEditorAction(bundleID: "com.microsoft.VSCode")
        try await action.handle(filePaths: [])
    }

    func testOpenInTerminalEmpty() async throws {
        let action = OpenInTerminalAction()
        try await action.handle(filePaths: [])
    }

    func testOpenInTerminalNormal() async throws {
        let action = OpenInTerminalAction()
        try await action.handle(filePaths: [testDir])
    }

    func testOpenInITerm2Empty() async throws {
        let action = OpenInITerm2Action()
        try await action.handle(filePaths: [])
    }

    func testOpenInITerm2Normal() async throws {
        let action = OpenInITerm2Action()
        try await action.handle(filePaths: [testDir])
    }
}
