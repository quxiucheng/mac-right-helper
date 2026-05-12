import Foundation
import ApplicationServices

enum PermissionStatus {
    case granted, denied, unknown
}

class PermissionManager {
    var fullDiskAccessStatus: PermissionStatus {
        let testURL = URL(fileURLWithPath: "~/Library/Safari")
        do {
            _ = try FileManager.default.contentsOfDirectory(atPath: testURL.path)
            return .granted
        } catch {
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
