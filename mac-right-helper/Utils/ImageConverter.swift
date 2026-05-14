import Foundation
import AppKit
import CoreGraphics
import ImageIO

enum ImageConverter {
    enum ConversionError: Error {
        case loadFailed
        case writeFailed
        case invalidSize
    }

    static func convertToICNS(inputPath: String, outputPath: String) throws {
        guard let image = NSImage(contentsOfFile: inputPath) else {
            throw ConversionError.loadFailed
        }

        let sizes: [CGFloat] = [16, 32, 64, 128, 256, 512]
        var images: [NSImage] = []
        for size in sizes {
            if let resized = image.resized(to: NSSize(width: size, height: size)) {
                images.append(resized)
            }
        }

        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw ConversionError.loadFailed
        }

        guard let destination = CGImageDestinationCreateWithURL(
            URL(fileURLWithPath: outputPath) as CFURL,
            kUTTypeAppleICNS, images.count, nil
        ) else {
            throw ConversionError.writeFailed
        }

        for img in images {
            if let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                CGImageDestinationAddImage(destination, cg, nil)
            }
        }

        if !CGImageDestinationFinalize(destination) {
            throw ConversionError.writeFailed
        }
    }

    static func convertToIOSIcons(inputPath: String, outputDir: String) throws {
        let sizes = [
            (29, "29x29"), (40, "40x40"), (58, "58x58"), (57, "57x57"),
            (114, "114x114"), (120, "120x120"), (180, "180x180"),
            (50, "50x50"), (80, "80x80"), (100, "100x100"),
            (72, "72x72"), (76, "76x76"), (144, "144x144"),
            (153, "153x153"), (160, "160x160"),
            (48, "48x48"), (55, "55x55"), (87, "87x87"),
            (88, "88x88"), (172, "172x172"), (196, "196x196")
        ]
        try generateIconSet(inputPath: inputPath, outputDir: outputDir, sizes: sizes)
    }

    static func convertToMacIcons(inputPath: String, outputDir: String) throws {
        let sizes = [
            (16, "16x16"), (32, "32x32"), (64, "64x64"),
            (128, "128x128"), (256, "256x256"), (512, "512x512"), (1024, "1024x1024")
        ]
        try generateIconSet(inputPath: inputPath, outputDir: outputDir, sizes: sizes)
    }

    private static func generateIconSet(
        inputPath: String, outputDir: String,
        sizes: [(Int, String)]
    ) throws {
        guard let image = NSImage(contentsOfFile: inputPath),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw ConversionError.loadFailed
        }

        try FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

        for (size, label) in sizes {
            let scaled = NSSize(width: size, height: size)
            guard let resized = image.resized(to: scaled),
                  let resizedCG = resized.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                continue
            }
            let outputPath = (outputDir as NSString).appendingPathComponent("icon_\(label).png")
            let url = URL(fileURLWithPath: outputPath)
            guard let destination = CGImageDestinationCreateWithURL(url as CFURL, kUTTypePNG, 1, nil) else {
                continue
            }
            CGImageDestinationAddImage(destination, resizedCG, nil)
            CGImageDestinationFinalize(destination)
        }
    }
}

private extension NSImage {
    func resized(to newSize: NSSize) -> NSImage? {
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        self.draw(in: NSRect(origin: .zero, size: newSize),
                  from: NSRect(origin: .zero, size: self.size),
                  operation: .copy, fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }
}
