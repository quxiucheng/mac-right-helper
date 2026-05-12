import XCTest
import AppKit
@testable import mac_right_helper

final class PasteboardReaderTests: XCTestCase {
    func testExtractFilePaths() {
        let pb = NSPasteboard(name: .init("test"))
        pb.clearContents()
        pb.setString("/tmp/test.txt", forType: .fileURL)

        let paths = PasteboardReader.extractFilePaths(from: pb)
        XCTAssertEqual(paths, ["/tmp/test.txt"])
    }
}
