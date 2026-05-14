import XCTest
@testable import mac_right_helper

final class ServiceActionsTests: XCTestCase {
    private var testFile: String!

    override func setUp() {
        super.setUp()
        testFile = "/tmp/mac-right-helper-service-test.txt"
        try? "hello world".data(using: .utf8)?.write(to: URL(fileURLWithPath: testFile))
    }

    override func tearDown() {
        try? FileManager.default.removeItem(atPath: testFile)
        super.tearDown()
    }

    func testTranslateBaiduEmpty() async throws {
        let action = TranslateBaiduAction()
        try await action.handle(filePaths: [])
    }

    func testTranslateGoogleEmpty() async throws {
        let action = TranslateGoogleAction()
        try await action.handle(filePaths: [])
    }

    func testToQRCodeEmpty() async throws {
        let action = ToQRCodeAction()
        try await action.handle(filePaths: [])
    }

    func testToQRCodeNormal() async throws {
        let action = ToQRCodeAction()
        try await action.handle(filePaths: [testFile])
    }
}
