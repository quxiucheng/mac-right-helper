import Foundation
import AppKit

struct TranslateBaiduAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard let path = filePaths.first else { return }
        let text: String
        if let data = FileManager.default.contents(atPath: path),
           let str = String(data: data, encoding: .utf8) {
            text = str.prefix(500).trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            text = URL(fileURLWithPath: path).lastPathComponent
        }
        TranslationHelper.translateBaidu(text: text)
    }
}

struct TranslateGoogleAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard let path = filePaths.first else { return }
        let text: String
        if let data = FileManager.default.contents(atPath: path),
           let str = String(data: data, encoding: .utf8) {
            text = str.prefix(500).trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            text = URL(fileURLWithPath: path).lastPathComponent
        }
        TranslationHelper.translateGoogle(text: text)
    }
}

struct ToQRCodeAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard let path = filePaths.first else { return }
        let text: String
        if let data = FileManager.default.contents(atPath: path),
           let str = String(data: data, encoding: .utf8) {
            text = str.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            text = URL(fileURLWithPath: path).lastPathComponent
        }
        try QRCodeGenerator.generateToPasteboard(text: text)
    }
}
