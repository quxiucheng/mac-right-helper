import Foundation
import AppKit

enum AirDropHelper {
    static func share(files: [String]) {
        let urls = files.map { URL(fileURLWithPath: $0) }
        let picker = NSSharingServicePicker(items: urls)

        if let button = NSApp.keyWindow?.contentView {
            picker.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
        }
    }

    static func shareViaAppleScript(files: [String]) {
        let paths = files.map { "\"\($0)\"" }.joined(separator: ", ")
        let script = """
        tell application "Finder"
            set theItems to { \(paths) }
            activate
        end tell
        """
        var errorInfo: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&errorInfo)
        }
    }
}
