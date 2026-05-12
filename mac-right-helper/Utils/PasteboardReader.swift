import Foundation
import AppKit

enum PasteboardReader {
    static func extractFilePaths(from pasteboard: NSPasteboard) -> [String] {
        guard let items = pasteboard.pasteboardItems else { return [] }
        var paths: [String] = []
        for item in items {
            if let urlData = item.data(forType: .fileURL),
               let url = URL(dataRepresentation: urlData, relativeTo: nil) {
                paths.append(url.path)
            }
        }
        return paths
    }
}
