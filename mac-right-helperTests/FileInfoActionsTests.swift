import XCTest
@testable import mac_right_helper

final class FileInfoActionsTests: XCTestCase {
    private var testFile: String!

    override func setUp() {
        super.setUp()
        testFile = "/tmp/mac-right-helper-hash-test.txt"
        try? "hello".data(using: .utf8)?.write(to: URL(fileURLWithPath: testFile))
    }

    override func tearDown() {
        try? FileManager.default.removeItem(atPath: testFile)
        super.tearDown()
    }

    func testShowFileInfoEmpty() async throws {
        let action = ShowFileInfoAction()
        try await action.handle(filePaths: [])
    }

    func testShowFileInfoNormal() async throws {
        let action = ShowFileInfoAction()
        try await action.handle(filePaths: [testFile])
    }
}
