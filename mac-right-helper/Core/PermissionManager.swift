import Foundation
import AppKit
import ApplicationServices

enum PermissionStatus {
    case granted, denied, unknown
}

class PermissionManager {
    var fullDiskAccessStatus: PermissionStatus {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let testURL = home.appendingPathComponent("Library/Safari")
        do {
            _ = try FileManager.default.contentsOfDirectory(atPath: testURL.path)
            return .granted
        } catch let error as NSError {
            if error.domain == NSCocoaErrorDomain,
               error.code == NSFileReadNoSuchFileError {
                return .unknown
            }
            return .denied
        }
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
