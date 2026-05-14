import Foundation
import AppKit

struct ImageToICNSAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard let path = filePaths.first else { return }
        let parent = URL(fileURLWithPath: path).deletingLastPathComponent().path
        let base = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
        let output = (parent as NSString).appendingPathComponent("\(base).icns")
        try ImageConverter.convertToICNS(inputPath: path, outputPath: output)
    }
}

struct ImageToIOSIconsAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard let path = filePaths.first else { return }
        let parent = URL(fileURLWithPath: path).deletingLastPathComponent().path
        let base = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
        let outputDir = (parent as NSString).appendingPathComponent("\(base).ios.iconset")
        try ImageConverter.convertToIOSIcons(inputPath: path, outputDir: outputDir)
    }
}

struct ImageToMacIconsAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard let path = filePaths.first else { return }
        let parent = URL(fileURLWithPath: path).deletingLastPathComponent().path
        let base = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
        let outputDir = (parent as NSString).appendingPathComponent("\(base).mac.iconset")
        try ImageConverter.convertToMacIcons(inputPath: path, outputDir: outputDir)
    }
}

struct SetCustomIconAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard filePaths.count >= 2 else { return }
        let imagePath = filePaths[0]
        for i in 1..<filePaths.count {
            try IconSetter.setIcon(imagePath: imagePath, for: filePaths[i])
        }
    }
}
