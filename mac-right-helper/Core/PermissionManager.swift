import Foundation
import AppKit
import ApplicationServices

enum PermissionStatus {
    case granted, denied, unknown
}

class PermissionManager {
    var fullDiskAccessStatus: PermissionStatus {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let checkPaths = [
            "Library/Safari",
            "Library/Mail",
            "Library/Messages",
            "Library/Application Scripts",
        ]
        for path in checkPaths {
            let testURL = home.appendingPathComponent(path)
            do {
                _ = try FileManager.default.contentsOfDirectory(atPath: testURL.path)
                return .granted
            } catch let error as NSError {
                if error.domain == NSCocoaErrorDomain,
                   error.code == NSFileReadNoSuchFileError {
                    continue
                }
                return .denied
            }
        }
        return .unknown
    }

    var accessibilityStatus: PermissionStatus {
        let opts = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: false] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(opts)
        if !trusted {
            // Log path for debugging - helps identify path mismatch issues
            NSLog("[mac-right-helper] Accessibility permission not granted for path: \(currentExecutablePath)")
        }
        return trusted ? .granted : .denied
    }

    /// Actively prompt the user to grant accessibility permission via the system dialog.
    /// Returns true if permission was already granted or the user granted it in response to the prompt.
    @discardableResult
    func requestAccessibilityPermission() -> Bool {
        let opts = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(opts)
    }

    func openSystemPreferencesPrivacy() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")!
        NSWorkspace.shared.open(url)
    }

    func openSystemPreferencesPrivacyAccessibility() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    /// Returns the current executable path for debugging permission issues
    var currentExecutablePath: String {
        return Bundle.main.bundlePath
    }
}
