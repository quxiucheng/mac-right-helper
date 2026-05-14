import XCTest
@testable import mac_right_helper

final class SystemActionsTests: XCTestCase {
    private var testDir: String!
    private var testFile: String!

    override func setUp() {
        super.setUp()
        testDir = "/tmp/mac-right-helper-test-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(atPath: testDir, withIntermediateDirectories: true)
        testFile = (testDir as NSString).appendingPathComponent("script.sh")
        FileManager.default.createFile(atPath: testFile, contents: "#!/bin/bash\necho hello".data(using: .utf8))
    }

    override func tearDown() {
        try? FileManager.default.removeItem(atPath: testDir)
        super.tearDown()
    }

    // MARK: - ToggleHiddenFilesAction
    func testToggleHiddenFilesEmpty() async throws {
        let action = ToggleHiddenFilesAction()
        try await action.handle(filePaths: [])
    }

    // MARK: - ChangePermissionsAction
    func testChangePermissionsEmpty() async throws {
        let action = ChangePermissionsAction()
        try await action.handle(filePaths: [])
    }

    func testChangePermissionsNormal() async throws {
        let action = ChangePermissionsAction()
        try await action.handle(filePaths: [testFile])
        let attrs = try FileManager.default.attributesOfItem(atPath: testFile)
        let perms = attrs[.posixPermissions] as? NSNumber
        XCTAssertNotNil(perms)
        XCTAssertEqual(perms?.intValue & 0o111, 0o111)
    }

    // MARK: - CreateSymlinkAction
    func testCreateSymlinkEmpty() async throws {
        let action = CreateSymlinkAction()
        try await action.handle(filePaths: [])
    }

    func testCreateSymlinkSinglePath() async throws {
        let action = CreateSymlinkAction()
        try await action.handle(filePaths: [testFile])
    }

    func testCreateSymlinkNormal() async throws {
        let action = CreateSymlinkAction()
        let linkPath = (testDir as NSString).appendingPathComponent("link.sh")
        try await action.handle(filePaths: [testFile, linkPath])
        XCTAssertTrue(FileManager.default.fileExists(atPath: linkPath))
        let dest = try FileManager.default.destinationOfSymbolicLink(atPath: linkPath)
        XCTAssertEqual(dest, testFile)
    }

    // MARK: - OpenParentDirectoryAction
    func testOpenParentDirectoryEmpty() async throws {
        let action = OpenParentDirectoryAction()
        try await action.handle(filePaths: [])
    }

    func testOpenParentDirectoryNormal() async throws {
        let action = OpenParentDirectoryAction()
        try await action.handle(filePaths: [testFile])
    }
}
