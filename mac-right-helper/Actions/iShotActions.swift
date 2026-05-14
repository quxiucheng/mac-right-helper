import Foundation
import AppKit

struct IShotScreenshotAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        let url = URL(string: "ishot://screenshot")!
        if NSWorkspace.shared.urlForApplication(toOpen: url) != nil {
            NSWorkspace.shared.open(url)
        } else {
            await MainActor.run {
                let alert = NSAlert()
                alert.messageText = "iShot Not Installed"
                alert.informativeText = "Please install iShot from the App Store."
                alert.alertStyle = .informational
                alert.runModal()
            }
        }
    }
}

struct IShotAnnotateAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard let path = filePaths.first else { return }
        let encoded = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        let url = URL(string: "ishot://annotate?path=\(encoded)")!
        if NSWorkspace.shared.urlForApplication(toOpen: url) != nil {
            NSWorkspace.shared.open(url)
        } else {
            await MainActor.run {
                let alert = NSAlert()
                alert.messageText = "iShot Not Installed"
                alert.informativeText = "Please install iShot from the App Store."
                alert.alertStyle = .informational
                alert.runModal()
            }
        }
    }
}
