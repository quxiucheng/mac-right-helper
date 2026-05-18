import XCTest
import AppKit
@testable import mac_right_helper

final class PasteboardReaderTests: XCTestCase {
    func testExtractFilePaths() {
        let pb = NSPasteboard(name: .init("test"))
        pb.clearContents()
        let url = NSURL(fileURLWithPath: "/tmp/test.txt")
        pb.writeObjects([url])

        let paths = PasteboardReader.extractFilePaths(from: pb)
        XCTAssertEqual(paths, ["/tmp/test.txt"])
    }
}
