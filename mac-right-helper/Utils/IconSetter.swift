import Foundation
import AppKit

enum IconSetter {
    enum IconError: Error {
        case loadFailed
        case setFailed
    }

    static func setIcon(imagePath: String, for targetPath: String) throws {
        guard let image = NSImage(contentsOfFile: imagePath) else {
            throw IconError.loadFailed
        }
        let url = URL(fileURLWithPath: targetPath)
        let result = NSWorkspace.shared.setIcon(image, forFile: targetPath)
        if !result {
            throw IconError.setFailed
        }
    }
}
