import XCTest
@testable import mac_right_helper

final class AppExIPCTests: XCTestCase {
    func testSharedInstanceExists() {
        let ipc = AppExIPC.shared
        XCTAssertNotNil(ipc)
    }

    func testExtConfigCodableRoundtrip() {
        let actions = [
            ActionItem(id: "test", name: "Test", icon: "star", group: "File", enabled: true)
        ]
        let config = AppExIPC.ExtConfig(
            actions: actions,
            monitorDirs: ["/test"],
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )

        let data = try? JSONEncoder().encode(config)
        XCTAssertNotNil(data)

        let decoded = try? JSONDecoder().decode(AppExIPC.ExtConfig.self, from: data!)
        XCTAssertEqual(decoded?.actions.count, 1)
        XCTAssertEqual(decoded?.actions.first?.id, "test")
        XCTAssertEqual(decoded?.monitorDirs, ["/test"])
    }

    func testActionPayloadCodableRoundtrip() {
        let payload = AppExIPC.ActionPayload(
            actionID: "copyPath",
            filePaths: ["/tmp/test.txt"],
            trigger: "ctx-items",
            timestamp: Date(timeIntervalSince1970: 1_700_000_000)
        )

        let data = try? JSONEncoder().encode(payload)
        XCTAssertNotNil(data)

        let decoded = try? JSONDecoder().decode(AppExIPC.ActionPayload.self, from: data!)
        XCTAssertEqual(decoded?.actionID, "copyPath")
        XCTAssertEqual(decoded?.filePaths, ["/tmp/test.txt"])
        XCTAssertEqual(decoded?.trigger, "ctx-items")
    }

    func testWriteAndReadConfig() {
        let ipc = AppExIPC.shared
        let actions = [
            ActionItem(id: "copyPath", name: "Copy Path", icon: "doc", group: "File", enabled: true)
        ]
        ipc.writeConfig(actions: actions, monitorDirs: ["/Users"])

        let config = ipc.readConfig()
        XCTAssertNotNil(config)
        XCTAssertEqual(config?.actions.count, 1)
        XCTAssertEqual(config?.actions.first?.id, "copyPath")
        XCTAssertEqual(config?.monitorDirs, ["/Users"])
    }

    func testWriteAndPollAction() {
        let ipc = AppExIPC.shared
        ipc.writeAction(actionID: "openInTerminal", filePaths: ["/tmp"], trigger: "toolbar")

        let payload = ipc.pollAction()
        XCTAssertNotNil(payload)
        XCTAssertEqual(payload?.actionID, "openInTerminal")
        XCTAssertEqual(payload?.filePaths, ["/tmp"])

        // Polling again should return nil because the file is deleted after first read
        let second = ipc.pollAction()
        XCTAssertNil(second)
    }

    func testStaleConfigReturnsNil() {
        let ipc = AppExIPC.shared
        let actions = [ActionItem(id: "old", name: "Old", icon: "doc", group: "File", enabled: true)]

        // Write config with a timestamp 20 seconds ago (beyond the 15s stale interval)
        let oldDate = Date().addingTimeInterval(-20)
        let staleConfig = AppExIPC.ExtConfig(actions: actions, monitorDirs: ["/"], updatedAt: oldDate)
        if let data = try? JSONEncoder().encode(staleConfig) {
            try? data.write(to: ipc.configFile, options: .atomic)
        }

        let config = ipc.readConfig()
        XCTAssertNil(config)
    }
}
