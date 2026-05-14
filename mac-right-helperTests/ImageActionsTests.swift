import XCTest
@testable import mac_right_helper

final class ImageActionsTests: XCTestCase {
    private var testDir: String!
    private var testImage: String!

    override func setUp() {
        super.setUp()
        testDir = "/tmp/mac-right-helper-test-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(atPath: testDir, withIntermediateDirectories: true)
        testImage = (testDir as NSString).appendingPathComponent("test.png")

        let image = NSImage(size: NSSize(width: 512, height: 512))
        image.lockFocus()
        NSColor.red.setFill()
        NSRect(origin: .zero, size: image.size).fill()
        image.unlockFocus()

        if let tiff = image.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff),
           let png = rep.representation(using: .png, properties: [:]) {
            try? png.write(to: URL(fileURLWithPath: testImage))
        }
    }

    override func tearDown() {
        try? FileManager.default.removeItem(atPath: testDir)
        super.tearDown()
    }

    func testImageToICNSEmpty() async throws {
        let action = ImageToICNSAction()
        try await action.handle(filePaths: [])
    }

    func testImageToICNSNormal() async throws {
        let action = ImageToICNSAction()
        try await action.handle(filePaths: [testImage])
        let icnsPath = (testDir as NSString).appendingPathComponent("test.icns")
        XCTAssertTrue(FileManager.default.fileExists(atPath: icnsPath))
    }

    func testImageToIOSIconsEmpty() async throws {
        let action = ImageToIOSIconsAction()
        try await action.handle(filePaths: [])
    }

    func testImageToMacIconsEmpty() async throws {
        let action = ImageToMacIconsAction()
        try await action.handle(filePaths: [])
    }

    func testSetCustomIconEmpty() async throws {
        let action = SetCustomIconAction()
        try await action.handle(filePaths: [])
    }

    func testSetCustomIconSinglePath() async throws {
        let action = SetCustomIconAction()
        try await action.handle(filePaths: [testImage])
    }
}
