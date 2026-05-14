import XCTest
@testable import mac_right_helper

final class FileActionsTests: XCTestCase {
    private var testFile: String!
    private var testDir: String!

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

    // MARK: - CopyPathAction
    func testCopyPathEmpty() async throws {
        let action = CopyPathAction()
        try await action.handle(filePaths: [])
    }

    func testCopyPathNormal() async throws {
        let action = CopyPathAction()
        try await action.handle(filePaths: [testFile])
        let pasted = NSPasteboard.general.string(forType: .string)
        XCTAssertEqual(pasted, testFile)
    }

    // MARK: - CopyFileNameAction
    func testCopyFileNameEmpty() async throws {
        let action = CopyFileNameAction()
        try await action.handle(filePaths: [])
    }

    func testCopyFileNameNormal() async throws {
        let action = CopyFileNameAction()
        try await action.handle(filePaths: [testFile])
        let pasted = NSPasteboard.general.string(forType: .string)
        XCTAssertEqual(pasted, "test.txt")
    }

    // MARK: - NewFileAction
    func testNewFileEmpty() async throws {
        let action = NewFileAction()
        try await action.handle(filePaths: [])
    }

    func testNewFileInDirectory() async throws {
        let action = NewFileAction()
        try await action.handle(filePaths: [testDir])
        let newFile = (testDir as NSString).appendingPathComponent("Untitled.txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: newFile))
    }

    func testNewFileInFileParent() async throws {
        let action = NewFileAction()
        try await action.handle(filePaths: [testFile])
        let newFile = (testDir as NSString).appendingPathComponent("Untitled.txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: newFile))
    }

    // MARK: - CompressAction
    func testCompressEmpty() async throws {
        let action = CompressAction()
        try await action.handle(filePaths: [])
    }

    func testCompressNormal() async throws {
        let action = CompressAction()
        try await action.handle(filePaths: [testFile])
        let zipPath = (testDir as NSString).appendingPathComponent("test.txt.zip")
        XCTAssertTrue(FileManager.default.fileExists(atPath: zipPath))
    }

    // MARK: - DecompressAction
    func testDecompressEmpty() async throws {
        let action = DecompressAction()
        try await action.handle(filePaths: [])
    }

    func testDecompressNormal() async throws {
        let action = CompressAction()
        try await action.handle(filePaths: [testFile])
        let zipPath = (testDir as NSString).appendingPathComponent("test.txt.zip")

        let decompress = DecompressAction()
        let destDir = (testDir as NSString).appendingPathComponent("unzip")
        try? FileManager.default.createDirectory(atPath: destDir, withIntermediateDirectories: true)
        try await decompress.handle(filePaths: [zipPath])
    }

    // MARK: - MoveToAction
    func testMoveToEmpty() async throws {
        let action = MoveToAction()
        try await action.handle(filePaths: [])
    }

    // MARK: - CopyToAction
    func testCopyToEmpty() async throws {
        let action = CopyToAction()
        try await action.handle(filePaths: [])
    }
}
