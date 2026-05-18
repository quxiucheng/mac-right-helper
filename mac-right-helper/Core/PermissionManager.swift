import Foundation
import AppKit
import ApplicationServices

enum PermissionStatus {
    case granted, denied, unknown
}

class PermissionManager {
    var fullDiskAccessStatus: PermissionStatus {
        let home = FileManager.default.homeDirectoryForCurrentUser
        // Multiple protected paths — if any returns permission error, FDA is denied.
        // TCC may hide denial as "file not found", so we probe several paths to
        // reduce the chance of false .unknown.
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
        return AXIsProcessTrustedWithOptions(nil) ? .granted : .denied
    }

    func openSystemPreferencesPrivacy() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")!
        NSWorkspace.shared.open(url)
    }

    func openSystemPreferencesPrivacyAccessibility() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
