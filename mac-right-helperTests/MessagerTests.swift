import XCTest
@testable import mac_right_helper

final class MessagerTests: XCTestCase {

    func testMessagePayloadCodableRoundtrip() {
        let payload = MessagePayload(
            action: "actioning",
            target: ["/tmp/test.txt"],
            rid: "openInVSCode",
            trigger: "ctx-items"
        )

        guard let json = Self.encode(payload) else {
            XCTFail("Failed to encode payload")
            return
        }

        guard let decoded = Self.decode(json) else {
            XCTFail("Failed to decode payload")
            return
        }

        XCTAssertEqual(decoded.action, "actioning")
        XCTAssertEqual(decoded.target, ["/tmp/test.txt"])
        XCTAssertEqual(decoded.rid, "openInVSCode")
        XCTAssertEqual(decoded.trigger, "ctx-items")
    }

    func testMessagePayloadWithConfigJSON() {
        let items = [ActionItem(id: "a", name: "A", icon: "doc", group: "File", enabled: true)]
        let json = (try? JSONEncoder().encode(items)).flatMap { String(data: $0, encoding: .utf8) }

        let payload = MessagePayload(
            action: "running",
            target: ["/Users"],
            rid: "",
            trigger: "",
            configJSON: json
        )

        guard let encoded = Self.encode(payload),
              let decoded = Self.decode(encoded) else {
            XCTFail("Encode/decode failed")
            return
        }

        XCTAssertEqual(decoded.action, "running")
        XCTAssertEqual(decoded.target, ["/Users"])
        let parsed = decoded.parseActions()
        XCTAssertEqual(parsed.count, 1)
        XCTAssertEqual(parsed.first?.id, "a")
    }

    func testMsgKeyValues() {
        XCTAssertEqual(MsgKey.fromFinder, "RightHelperFromFinder")
        XCTAssertEqual(MsgKey.running, "RightHelperRunning")
        XCTAssertEqual(MsgKey.quit, "RightHelperQuit")
    }

    func testActionItemCodableRoundtrip() {
        let item = ActionItem(id: "test", name: "Test", icon: "star", group: "File", enabled: true)

        let data = try? JSONEncoder().encode(item)
        XCTAssertNotNil(data)

        let decoded = try? JSONDecoder().decode(ActionItem.self, from: data!)
        XCTAssertEqual(decoded?.id, "test")
        XCTAssertEqual(decoded?.name, "Test")
        XCTAssertEqual(decoded?.icon, "star")
        XCTAssertEqual(decoded?.group, "File")
        XCTAssertEqual(decoded?.enabled, true)
    }

    func testMessagerSharedInstanceExists() {
        let m = Messager.shared
        XCTAssertNotNil(m)
    }

    // MARK: - Helpers

    private static func encode(_ payload: MessagePayload) -> String? {
        guard let data = try? JSONEncoder().encode(payload) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func decode(_ json: String) -> MessagePayload? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(MessagePayload.self, from: data)
    }
}
