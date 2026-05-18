import XCTest
@testable import mac_right_helper

final class AppExIPCTests: XCTestCase {
    func testSharedInstanceExists() {
        let ipc = AppExIPC.shared
        XCTAssertNotNil(ipc)
    }

    func testIPCMessageCodableRoundtrip() {
        let actions = [
            ActionItem(id: "test", name: "Test", icon: "star", group: "File", enabled: true)
        ]
        let msg = AppExIPC.IPCMessage(
            type: "config",
            actions: actions,
            monitorDirs: ["/test"],
            actionID: nil,
            filePaths: nil,
            trigger: nil
        )

        let data = try? JSONEncoder().encode(msg)
        XCTAssertNotNil(data)

        let decoded = try? JSONDecoder().decode(AppExIPC.IPCMessage.self, from: data!)
        XCTAssertEqual(decoded?.type, "config")
        XCTAssertEqual(decoded?.actions?.count, 1)
        XCTAssertEqual(decoded?.actions?.first?.id, "test")
        XCTAssertEqual(decoded?.monitorDirs, ["/test"])
    }

    func testIPCMessageActionPayload() {
        let msg = AppExIPC.IPCMessage(
            type: "action",
            actions: nil,
            monitorDirs: nil,
            actionID: "copyPath",
            filePaths: ["/tmp/test.txt"],
            trigger: "ctx-items"
        )

        let data = try? JSONEncoder().encode(msg)
        let decoded = try? JSONDecoder().decode(AppExIPC.IPCMessage.self, from: data!)
        XCTAssertEqual(decoded?.actionID, "copyPath")
        XCTAssertEqual(decoded?.filePaths, ["/tmp/test.txt"])
        XCTAssertEqual(decoded?.trigger, "ctx-items")
    }

    func testIPCMessageHeartbeatPayload() {
        let msg = AppExIPC.IPCMessage(
            type: "heartbeat",
            actions: nil,
            monitorDirs: nil,
            actionID: nil,
            filePaths: nil,
            trigger: nil
        )

        let data = try? JSONEncoder().encode(msg)
        let decoded = try? JSONDecoder().decode(AppExIPC.IPCMessage.self, from: data!)
        XCTAssertEqual(decoded?.type, "heartbeat")
    }
}
