import XCTest
@testable import mac_right_helper

final class QRCodeGeneratorTests: XCTestCase {
    func testGenerateQRCode() throws {
        let image = try QRCodeGenerator.generate(text: "https://example.com")
        XCTAssertTrue(image.size.width > 0)
        XCTAssertTrue(image.size.height > 0)
    }

    func testGenerateToPasteboard() throws {
        try QRCodeGenerator.generateToPasteboard(text: "test")
        let images = NSPasteboard.general.readObjects(forClasses: [NSImage.self], options: nil)
        XCTAssertNotNil(images)
        XCTAssertTrue(images?.isEmpty == false)
    }
}
