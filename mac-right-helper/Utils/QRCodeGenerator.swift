import Foundation
import AppKit
import CoreImage

enum QRCodeGenerator {
    enum QRCodeError: Error {
        case generationFailed
        case bitmapCreationFailed
    }

    static func generate(text: String, size: CGFloat = 256) throws -> NSImage {
        let data = text.data(using: .utf8)
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            throw QRCodeError.generationFailed
        }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")

        guard let ciImage = filter.outputImage else {
            throw QRCodeError.generationFailed
        }

        let scaleX = size / ciImage.extent.size.width
        let scaleY = size / ciImage.extent.size.height
        let transformed = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        let rep = NSCIImageRep(ciImage: transformed)
        let nsImage = NSImage(size: NSSize(width: size, height: size))
        nsImage.addRepresentation(rep)
        return nsImage
    }

    static func generateToPasteboard(text: String) throws {
        let image = try generate(text: text)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([image])
    }
}
