import XCTest
@testable import mac_right_helper

final class TemplateActionsTests: XCTestCase {
    private var testDir: String!

    override func setUp() {
        super.setUp()
        testDir = "/tmp/mac-right-helper-test-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(atPath: testDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(atPath: testDir)
        super.tearDown()
    }

    func testNewFileWithTemplateEmpty() async throws {
        let action = NewFileWithTemplateAction(template: FileTemplate(id: "test", name: "Test", ext: "txt", content: "hello"))
        try await action.handle(filePaths: [])
    }

    func testNewFileWithTemplateNormal() async throws {
        let action = NewFileWithTemplateAction(template: FileTemplate(id: "test", name: "Test", ext: "md", content: "# Title"))
        try await action.handle(filePaths: [testDir])
        let files = try FileManager.default.contentsOfDirectory(atPath: testDir)
        let match = files.first { $0.hasSuffix(".md") }
        XCTAssertNotNil(match)
    }

    func testNewFolderFromFileNameEmpty() async throws {
        let action = NewFolderFromFileNameAction()
        try await action.handle(filePaths: [])
    }

    func testNewFolderFromFileNameNormal() async throws {
        let filePath = (testDir as NSString).appendingPathComponent("myfile.txt")
        FileManager.default.createFile(atPath: filePath, contents: nil)
        let action = NewFolderFromFileNameAction()
        try await action.handle(filePaths: [filePath])
        let folderPath = (testDir as NSString).appendingPathComponent("myfile")
        var isDir: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: folderPath, isDirectory: &isDir))
        XCTAssertTrue(isDir.boolValue)
    }
}
