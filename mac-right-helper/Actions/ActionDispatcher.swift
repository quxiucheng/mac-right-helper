import Foundation
import AppKit

enum ActionDispatcher {
    private static var handlers: [String: ActionHandler] = [
        // File
        "copyPath": CopyPathAction(),
        "copyFileName": CopyFileNameAction(),
        "newFile": NewFileAction(),
        "newFileWithTemplate": NewFileWithTemplateAction(template: FileTemplate(id: "tpl-txt", name: "Text", ext: "txt", content: "")),
        "newFolderFromFileName": NewFolderFromFileNameAction(),
        "compress": CompressAction(),
        "decompress": DecompressAction(),
        "moveTo": MoveToAction(),
        "copyTo": CopyToAction(),
        "cutFiles": CutFilesAction(),
        "sendToPicker": SendToPickerAction(),
        "sendAliasToDesktop": SendAliasToDesktopAction(),
        "trashPermanently": TrashPermanentlyAction(),
        "favoriteDirPicker": FavoriteDirPickerAction(),
        "showFileInfo": ShowFileInfoAction(),
        "airdrop": AirDropAction(),
        // Dev
        "openInVSCode": OpenInVSCodeAction(),
        "openInTerminal": OpenInTerminalAction(),
        "openInITerm2": OpenInITerm2Action(),
        "openInSublimeText": OpenInEditorAction(bundleID: "com.sublimetext.4"),
        "openInWarp": OpenInEditorAction(bundleID: "dev.warp.Warp-Stable"),
        "openInIDEA": OpenInEditorAction(bundleID: "com.jetbrains.intellij.ce"),
        "gitInit": GitInitAction(),
        "gitStatus": GitStatusAction(),
        "formatJSON": FormatJSONAction(),
        // System
        "toggleHiddenFiles": ToggleHiddenFilesAction(),
        "hideSelectedFiles": HideSelectedFilesAction(),
        "unhideSelectedFiles": UnhideSelectedFilesAction(),
        "changePermissions": ChangePermissionsAction(),
        "createSymlink": CreateSymlinkAction(),
        "openParentDirectory": OpenParentDirectoryAction(),
        // Image
        "imageToICNS": ImageToICNSAction(),
        "imageToIOSIcons": ImageToIOSIconsAction(),
        "imageToMacIcons": ImageToMacIconsAction(),
        "setCustomIcon": SetCustomIconAction(),
        // Service
        "translateBaidu": TranslateBaiduAction(),
        "translateGoogle": TranslateGoogleAction(),
        "toQRCode": ToQRCodeAction(),
        // iShot
        "iShotScreenshot": IShotScreenshotAction(),
        "iShotAnnotate": IShotAnnotateAction(),
        // Preferences
        "openPreferences": OpenPreferencesAction(),
    ]

    static func handler(for actionID: String) -> ActionHandler? {
        let config = ConfigManager.shared.config

        // Dynamic: templates
        if actionID.hasPrefix("tpl_"),
           let tpl = config.templates.first(where: { "tpl_\($0.id)" == actionID }) {
            guard config.builtinItems["newFileWithTemplate"]?.enabled != false else { return nil }
            return NewFileWithTemplateAction(template: tpl)
        }

        // Dynamic: favorite folders
        if actionID.hasPrefix("fav_"),
           let folder = config.favoriteFolders.first(where: { "fav_\($0.id)" == actionID }) {
            guard config.builtinItems["sendToPicker"]?.enabled != false else { return nil }
            return SendToFolderAction(folder: folder)
        }

        // Dynamic: favorite directories
        if actionID.hasPrefix("dir_"),
           let dir = config.favoriteDirectories.first(where: { "dir_\($0.id)" == actionID }) {
            guard config.builtinItems["favoriteDirPicker"]?.enabled != false else { return nil }
            return OpenDirectoryAction(directory: dir)
        }

        // Built-in
        if let builtIn = handlers[actionID] {
            guard config.builtinItems[actionID]?.enabled != false else {
                return nil
            }
            return builtIn
        }

        // Custom scripts
        if let script = config.customScripts.first(where: { $0.id == actionID }) {
            return CustomScriptHandler(script: script)
        }
        return nil
    }

    static func dispatch(actionID: String, filePaths: [String]) async {
        guard let handler = handler(for: actionID) else {
            print("No handler for action: \(actionID)")
            return
        }
        do {
            try await handler.handle(filePaths: filePaths)
        } catch {
            await MainActor.run {
                let alert = NSAlert()
                alert.messageText = "Action Failed"
                alert.informativeText = "\(error)"
                alert.alertStyle = .warning
                alert.runModal()
            }
        }
    }
}

// MARK: - Dynamic Actions

struct SendToFolderAction: ActionHandler {
    let folder: FavoriteFolder

    func handle(filePaths: [String]) async throws {
        guard !filePaths.isEmpty else { return }
        let destURL = URL(fileURLWithPath: folder.path.expandingTilde())
        for path in filePaths {
            let name = URL(fileURLWithPath: path).lastPathComponent
            let destPath = destURL.appendingPathComponent(name).path
            try FileManager.default.copyItem(atPath: path, toPath: destPath)
        }
    }
}

struct OpenDirectoryAction: ActionHandler {
    let directory: FavoriteDirectory

    func handle(filePaths: [String]) async throws {
        let path = directory.path.expandingTilde()
        NSWorkspace.shared.open(URL(fileURLWithPath: path))
    }
}

private extension String {
    func expandingTilde() -> String {
        return self.replacingOccurrences(of: "~", with: FileManager.default.homeDirectoryForCurrentUser.path)
    }
}
