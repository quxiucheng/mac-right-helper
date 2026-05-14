import XCTest
@testable import mac_right_helper

final class DevActionsTests: XCTestCase {
    private var testDir: String!
    private var testFile: String!

    override func setUp() {
        super.setUp()
        testDir = "/tmp/mac-right-helper-test-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(atPath: testDir, withIntermediateDirectories: true)
        testFile = (testDir as NSString).appendingPathComponent("test.json")
        FileManager.default.createFile(atPath: testFile, contents: nil)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(atPath: testDir)
        super.tearDown()
    }

    // MARK: - OpenInVSCodeAction
    func testOpenInVSCodeEmpty() async throws {
        let action = OpenInVSCodeAction()
        try await action.handle(filePaths: [])
    }

    func testOpenInVSCodeNormal() async throws {
        let action = OpenInVSCodeAction()
        try await action.handle(filePaths: [testFile])
    }

    // MARK: - OpenInTerminalAction
    func testOpenInTerminalEmpty() async throws {
        let action = OpenInTerminalAction()
        try await action.handle(filePaths: [])
    }

    func testOpenInTerminalNormal() async throws {
        let action = OpenInTerminalAction()
        try await action.handle(filePaths: [testDir])
    }

    func testOpenInTerminalWithFile() async throws {
        let action = OpenInTerminalAction()
        try await action.handle(filePaths: [testFile])
    }

    // MARK: - GitInitAction
    func testGitInitEmpty() async throws {
        let action = GitInitAction()
        try await action.handle(filePaths: [])
    }

    func testGitInitNormal() async throws {
        let action = GitInitAction()
        try await action.handle(filePaths: [testDir])
        let gitDir = (testDir as NSString).appendingPathComponent(".git")
        XCTAssertTrue(FileManager.default.fileExists(atPath: gitDir))
    }

    // MARK: - GitStatusAction
    func testGitStatusEmpty() async throws {
        let action = GitStatusAction()
        try await action.handle(filePaths: [])
    }

    func testGitStatusNormal() async throws {
        let gitInit = GitInitAction()
        try await gitInit.handle(filePaths: [testDir])
        let action = GitStatusAction()
        try await action.handle(filePaths: [testDir])
    }

    // MARK: - FormatJSONAction
    func testFormatJSONEmpty() async throws {
        let action = FormatJSONAction()
        try await action.handle(filePaths: [])
    }

    func testFormatJSONNormal() async throws {
        let json = "{\"name\":\"test\"}"
        try json.data(using: .utf8)?.write(to: URL(fileURLWithPath: testFile))
        let action = FormatJSONAction()
        try await action.handle(filePaths: [testFile])
        let data = try Data(contentsOf: URL(fileURLWithPath: testFile))
        let content = String(data: data, encoding: .utf8) ?? ""
        XCTAssertTrue(content.contains("\"name\""))
    }

    func testFormatJSONInvalid() async {
        let invalid = "not json"
        try? invalid.data(using: .utf8)?.write(to: URL(fileURLWithPath: testFile))
        let action = FormatJSONAction()
        do {
            try await action.handle(filePaths: [testFile])
            XCTFail("Should have thrown")
        } catch {
            // expected
        }
    }
}
