import Foundation

/// Manages registration and status checking for the Finder Sync Extension.
struct ExtensionManager {

    /// The expected bundle identifier of the embedded Finder Sync Extension.
    static let extensionBundleID = "com.example.mac-right-helper.FinderSyncExt"

    /// The expected name of the embedded extension bundle.
    static let extensionBundleName = "FinderSyncExt.appex"

    /// Returns the URL to the embedded Finder Sync Extension inside the main app bundle.
    static func embeddedExtensionURL() -> URL? {
        Bundle.main.builtInPlugInsURL?.appendingPathComponent(extensionBundleName)
    }

    /// Registers the embedded extension with the system so it appears in
    /// System Settings > Extensions. Does nothing if the extension bundle is missing.
    static func registerExtension() {
        guard let url = embeddedExtensionURL(),
              FileManager.default.fileExists(atPath: url.path) else { return }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pluginkit")
        task.arguments = ["-a", url.path]
        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            // Silently ignore — may already be registered or pluginkit unavailable
        }
    }

    /// Checks whether the Finder Sync Extension is enabled via pluginkit.
    /// Returns `false` if the extension is not registered or not enabled.
    static func isExtensionEnabled() -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pluginkit")
        task.arguments = ["-m", "-i", extensionBundleID]
        let pipe = Pipe()
        task.standardOutput = pipe
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return false }
            // pluginkit output contains a '+' prefix when the extension is enabled
            return output.contains("+")
        } catch {
            return false
        }
    }
}
