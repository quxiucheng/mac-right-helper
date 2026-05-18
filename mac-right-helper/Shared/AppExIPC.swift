import Foundation

/// Reliable IPC between main app and Finder Sync Extension.
/// Uses CFNotificationCenterGetDarwinNotifyCenter() for lightweight signaling
/// and a shared JSON file for config data.
///
/// Darwin notifications work at the kernel level and do not depend on Mach
/// messaging, making them reliable across process boundaries even when
/// DistributedNotificationCenter is blocked or unreliable.
final class AppExIPC {

    // MARK: - Singleton

    static let shared = AppExIPC()

    // MARK: - Notification names

    private enum Note {
        static let extHeartbeat = "com.example.mac-right-helper.ext.heartbeat"
        static let appConfig    = "com.example.mac-right-helper.app.config"
        static let appQuit      = "com.example.mac-right-helper.app.quit"
        static let extAction    = "com.example.mac-right-helper.ext.action"
    }

    // MARK: - File paths

    private let syncDir: URL = {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        return appSupport.appendingPathComponent("mac-right-helper")
    }()

    private var syncFile: URL {
        syncDir.appendingPathComponent("ipc-sync.json")
    }

    // MARK: - Types

    struct IPCMessage: Codable {
        var type: String = ""        // "heartbeat", "config", "action", "quit"
        var actions: [ActionItem]?   // config sync payload
        var monitorDirs: [String]?   // config sync payload
        var actionID: String?        // action dispatch payload
        var filePaths: [String]?     // action dispatch payload
        var trigger: String?         // action dispatch payload
    }

    // MARK: - Handler registration

    private var heartbeatHandler: (() -> Void)?
    private var configHandler: (([ActionItem], [String]) -> Void)?
    private var quitHandler: (() -> Void)?
    private var actionHandler: ((String, [String], String) -> Void)?

    private var handlers: [String: () -> Void] = [:]
    private var observedNames: [String] = []

    private let center = CFNotificationCenterGetDarwinNotifyCenter()
    private let queue = DispatchQueue(label: "com.example.mac-right-helper.ipc")

    // MARK: - Init

    init() {
        try? FileManager.default.createDirectory(
            at: syncDir, withIntermediateDirectories: true
        )
    }

    deinit {
        for name in observedNames {
            CFNotificationCenterRemoveObserver(
                center,
                Unmanaged.passUnretained(self).toOpaque(),
                name as CFString,
                nil
            )
        }
    }

    // MARK: - Send

    /// Extension sends a heartbeat to the main app.
    func sendHeartbeat() {
        writeMessage(IPCMessage(type: "heartbeat"))
        post(Note.extHeartbeat)
    }

    /// Main app sends config and monitor directories to the extension.
    func sendConfig(actions: [ActionItem], monitorDirs: [String]) {
        writeMessage(IPCMessage(
            type: "config",
            actions: actions,
            monitorDirs: monitorDirs
        ))
        post(Note.appConfig)
    }

    /// Main app notifies the extension that it is quitting.
    func sendQuit() {
        writeMessage(IPCMessage(type: "quit"))
        post(Note.appQuit)
    }

    /// Extension asks the main app to execute an action on selected files.
    func sendAction(actionID: String, filePaths: [String], trigger: String) {
        writeMessage(IPCMessage(
            type: "action",
            actionID: actionID,
            filePaths: filePaths,
            trigger: trigger
        ))
        post(Note.extAction)
    }

    // MARK: - Receive (register handlers)

    func onHeartbeat(_ handler: @escaping () -> Void) {
        heartbeatHandler = handler
        observe(Note.extHeartbeat) { [weak self] in
            self?.heartbeatHandler?()
        }
    }

    func onConfig(_ handler: @escaping ([ActionItem], [String]) -> Void) {
        configHandler = handler
        observe(Note.appConfig) { [weak self] in
            guard let self, let msg = self.readMessage() else { return }
            let actions = msg.actions ?? []
            let dirs = msg.monitorDirs ?? []
            self.configHandler?(actions, dirs)
        }
    }

    func onQuit(_ handler: @escaping () -> Void) {
        quitHandler = handler
        observe(Note.appQuit) { [weak self] in
            self?.quitHandler?()
        }
    }

    func onAction(_ handler: @escaping (String, [String], String) -> Void) {
        actionHandler = handler
        observe(Note.extAction) { [weak self] in
            guard let self, let msg = self.readMessage() else { return }
            let id = msg.actionID ?? ""
            let files = msg.filePaths ?? []
            let trigger = msg.trigger ?? ""
            guard !id.isEmpty, !files.isEmpty else { return }
            self.actionHandler?(id, files, trigger)
        }
    }

    // MARK: - CFNotificationCenter primitives

    private func post(_ name: String) {
        CFNotificationCenterPostNotification(
            center,
            CFNotificationName(rawValue: name as CFString),
            nil,
            nil,
            true
        )
    }

    private func observe(_ name: String, handler: @escaping () -> Void) {
        handlers[name] = handler
        observedNames.append(name)
        CFNotificationCenterAddObserver(
            center,
            Unmanaged.passUnretained(self).toOpaque(),
            { _, observer, notificationName, _, _ in
                guard let observer = observer,
                      let notificationName = notificationName else { return }
                let ipc = Unmanaged<AppExIPC>.fromOpaque(observer).takeUnretainedValue()
                let nameString = notificationName.rawValue as String
                DispatchQueue.main.async {
                    ipc.handlers[nameString]?()
                }
            },
            name as CFString,
            nil,
            .deliverImmediately
        )
    }

    // MARK: - File-based payload

    private func writeMessage(_ msg: IPCMessage) {
        queue.sync {
            guard let data = try? JSONEncoder().encode(msg) else { return }
            try? data.write(to: syncFile, options: .atomic)
        }
    }

    private func readMessage() -> IPCMessage? {
        queue.sync {
            guard let data = try? Data(contentsOf: syncFile),
                  let msg = try? JSONDecoder().decode(IPCMessage.self, from: data)
            else { return nil }
            return msg
        }
    }
}
