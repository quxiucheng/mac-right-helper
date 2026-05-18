import Foundation

/// Reliable IPC between main app and Finder Sync Extension using file-based polling.
/// All cross-process communication is done through shared JSON files in
/// ~/Library/Application Support/mac-right-helper/, eliminating the need for
/// Darwin notifications or Mach messaging which are fragile in ad-hoc signed apps.
final class AppExIPC {

    static let shared = AppExIPC()

    // MARK: - File paths

    private let syncDir: URL = {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        return appSupport.appendingPathComponent("mac-right-helper")
    }()

    var configFile: URL { syncDir.appendingPathComponent("ext-config.json") }
    var actionFile: URL { syncDir.appendingPathComponent("ext-action.json") }

    /// Config becomes stale after this interval if main app stops updating it.
    private let configStaleInterval: TimeInterval = 15

    // MARK: - Types

    struct ExtConfig: Codable {
        var actions: [ActionItem]
        var monitorDirs: [String]
        var updatedAt: Date
    }

    struct ActionPayload: Codable {
        var actionID: String
        var filePaths: [String]
        var trigger: String
        var timestamp: Date
    }

    private let queue = DispatchQueue(label: "com.example.mac-right-helper.ipc")

    // MARK: - Init

    init() {
        try? FileManager.default.createDirectory(
            at: syncDir, withIntermediateDirectories: true
        )
    }

    // MARK: - Config (main app writes, extension reads)

    /// Write current action list and monitor directories for the extension.
    func writeConfig(actions: [ActionItem], monitorDirs: [String]) {
        let config = ExtConfig(actions: actions, monitorDirs: monitorDirs, updatedAt: Date())
        queue.sync {
            guard let data = try? JSONEncoder().encode(config) else { return }
            try? data.write(to: configFile, options: .atomic)
        }
    }

    /// Read the latest config. Returns nil if the file is missing or too stale.
    func readConfig() -> ExtConfig? {
        queue.sync {
            guard let data = try? Data(contentsOf: configFile),
                  let config = try? JSONDecoder().decode(ExtConfig.self, from: data)
            else { return nil }

            let age = Date().timeIntervalSince(config.updatedAt)
            guard age < configStaleInterval else { return nil }
            return config
        }
    }

    // MARK: - Action (extension writes, main app polls)

    /// Extension writes an action request to be picked up by the main app.
    func writeAction(actionID: String, filePaths: [String], trigger: String) {
        let payload = ActionPayload(
            actionID: actionID,
            filePaths: filePaths,
            trigger: trigger,
            timestamp: Date()
        )
        queue.sync {
            guard let data = try? JSONEncoder().encode(payload) else { return }
            try? data.write(to: actionFile, options: .atomic)
        }
    }

    /// Main app polls for pending action requests.
    /// Returns the payload and atomically deletes the file so it is not processed twice.
    func pollAction() -> ActionPayload? {
        queue.sync {
            guard let data = try? Data(contentsOf: actionFile),
                  let payload = try? JSONDecoder().decode(ActionPayload.self, from: data)
            else { return nil }

            // Delete after reading to prevent duplicate dispatch
            try? FileManager.default.removeItem(at: actionFile)
            return payload
        }
    }

    /// Legacy helper — same as pollAction for cleaner call sites.
    func clearAction() {
        queue.sync {
            try? FileManager.default.removeItem(at: actionFile)
        }
    }
}
