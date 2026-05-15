import Foundation
import AppKit

struct ShowFileInfoAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard let path = filePaths.first else { return }
        let md5 = try FileHasher.hash(filePath: path, algorithm: .md5)
        let sha1 = try FileHasher.hash(filePath: path, algorithm: .sha1)
        let sha256 = try FileHasher.hash(filePath: path, algorithm: .sha256)
        let sha512 = try FileHasher.hash(filePath: path, algorithm: .sha512)

        let info = """
        MD5:    \(md5)
        SHA1:   \(sha1)
        SHA256: \(sha256)
        SHA512: \(sha512)
        """

        await MainActor.run {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(info, forType: .string)

            let alert = NSAlert()
            alert.messageText = L("fileInformation")
            alert.informativeText = info
            alert.alertStyle = .informational
            alert.addButton(withTitle: L("copyToClipboard"))
            alert.addButton(withTitle: L("ok"))
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(info, forType: .string)
            }
        }
    }
}
