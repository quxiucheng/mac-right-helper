import XCTest
@testable import mac_right_helper

final class FileHasherTests: XCTestCase {
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

    func testMD5() throws {
        let hash = try FileHasher.hash(filePath: testFile, algorithm: .md5)
        XCTAssertEqual(hash.count, 32)
    }

    func testSHA1() throws {
        let hash = try FileHasher.hash(filePath: testFile, algorithm: .sha1)
        XCTAssertEqual(hash.count, 40)
    }

    func testSHA256() throws {
        let hash = try FileHasher.hash(filePath: testFile, algorithm: .sha256)
        XCTAssertEqual(hash.count, 64)
    }

    func testSHA512() throws {
        let hash = try FileHasher.hash(filePath: testFile, algorithm: .sha512)
        XCTAssertEqual(hash.count, 128)
    }

    func testConsistentHash() throws {
        let h1 = try FileHasher.hash(filePath: testFile, algorithm: .md5)
        let h2 = try FileHasher.hash(filePath: testFile, algorithm: .md5)
        XCTAssertEqual(h1, h2)
    }
}
