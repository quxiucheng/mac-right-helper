import Foundation
import AppKit

struct CutFilesAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard !filePaths.isEmpty else { return }
        let urls = filePaths.map { URL(fileURLWithPath: $0) }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects(urls as [NSPasteboardWriting])

        let settings = ConfigManager.shared.config.settings
        if settings.cutHideFiles {
            for path in filePaths {
                var attrs = try FileManager.default.attributesOfItem(atPath: path)
                var perms = attrs[.posixPermissions] as? UInt16 ?? 0o644
                perms |= 0o100000
                attrs[.posixPermissions] = perms
            }
        }
    }
}
