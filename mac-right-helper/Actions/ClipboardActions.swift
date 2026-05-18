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
                var url = URL(fileURLWithPath: path)
                var resourceValues = URLResourceValues()
                resourceValues.isHidden = true
                try url.setResourceValues(resourceValues)
            }
        }
    }
}
