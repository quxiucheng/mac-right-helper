import Foundation
import AppKit

enum AirDropHelper {
    static func share(files: [String]) {
        let urls = files.map { URL(fileURLWithPath: $0) }
        let picker = NSSharingServicePicker(items: urls)

        if let contentView = NSApp.keyWindow?.contentView {
            picker.show(relativeTo: contentView.bounds, of: contentView, preferredEdge: .maxY)
        } else if let statusItem = (NSApp.delegate as? AppDelegate)?.statusItem {
            picker.show(relativeTo: .zero, of: statusItem.button!, preferredEdge: .maxY)
        } else {
            let service = NSSharingService(named: .sendViaAirDrop)
            service?.perform(withItems: urls)
        }
    }
}
