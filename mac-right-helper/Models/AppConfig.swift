import Foundation

struct AppConfig: Codable {
    var version: Int
    var builtinItems: [String: BuiltinItemConfig]
    var customScripts: [CustomScript]
    var templates: [FileTemplate]
    var favoriteFolders: [FavoriteFolder]
    var favoriteDirectories: [FavoriteDirectory]
    var settings: AppSettings

    struct BuiltinItemConfig: Codable {
        var enabled: Bool
        var weight: Int
        var group: String
    }

    static let defaultConfig: AppConfig = AppConfig(
        version: 2,
        builtinItems: [
            // File
            "copyPath": BuiltinItemConfig(enabled: true, weight: 10, group: "File"),
            "copyFileName": BuiltinItemConfig(enabled: true, weight: 11, group: "File"),
            "newFile": BuiltinItemConfig(enabled: true, weight: 20, group: "File"),
            "newFileWithTemplate": BuiltinItemConfig(enabled: true, weight: 21, group: "File"),
            "newFolderFromFileName": BuiltinItemConfig(enabled: true, weight: 22, group: "File"),
            "compress": BuiltinItemConfig(enabled: true, weight: 30, group: "File"),
            "decompress": BuiltinItemConfig(enabled: true, weight: 31, group: "File"),
            "moveTo": BuiltinItemConfig(enabled: true, weight: 40, group: "File"),
            "copyTo": BuiltinItemConfig(enabled: true, weight: 41, group: "File"),
            "cutFiles": BuiltinItemConfig(enabled: true, weight: 42, group: "File"),
            "sendToPicker": BuiltinItemConfig(enabled: true, weight: 43, group: "File"),
            "sendAliasToDesktop": BuiltinItemConfig(enabled: true, weight: 44, group: "File"),
            "trashPermanently": BuiltinItemConfig(enabled: true, weight: 50, group: "File"),
            "favoriteDirPicker": BuiltinItemConfig(enabled: true, weight: 60, group: "File"),
            "showFileInfo": BuiltinItemConfig(enabled: true, weight: 70, group: "File"),
            "airdrop": BuiltinItemConfig(enabled: true, weight: 80, group: "File"),
            // Dev
            "openInVSCode": BuiltinItemConfig(enabled: true, weight: 100, group: "Dev"),
            "openInTerminal": BuiltinItemConfig(enabled: true, weight: 101, group: "Dev"),
            "openInITerm2": BuiltinItemConfig(enabled: true, weight: 102, group: "Dev"),
            "openInSublimeText": BuiltinItemConfig(enabled: true, weight: 103, group: "Dev"),
            "openInWarp": BuiltinItemConfig(enabled: true, weight: 104, group: "Dev"),
            "openInIDEA": BuiltinItemConfig(enabled: true, weight: 105, group: "Dev"),
            "gitInit": BuiltinItemConfig(enabled: true, weight: 110, group: "Dev"),
            "gitStatus": BuiltinItemConfig(enabled: true, weight: 111, group: "Dev"),
            "formatJSON": BuiltinItemConfig(enabled: true, weight: 120, group: "Dev"),
            // System
            "toggleHiddenFiles": BuiltinItemConfig(enabled: true, weight: 200, group: "System"),
            "hideSelectedFiles": BuiltinItemConfig(enabled: true, weight: 201, group: "System"),
            "unhideSelectedFiles": BuiltinItemConfig(enabled: true, weight: 202, group: "System"),
            "changePermissions": BuiltinItemConfig(enabled: true, weight: 203, group: "System"),
            "createSymlink": BuiltinItemConfig(enabled: true, weight: 204, group: "System"),
            "openParentDirectory": BuiltinItemConfig(enabled: true, weight: 205, group: "System"),
            // Image
            "imageToICNS": BuiltinItemConfig(enabled: true, weight: 300, group: "Image"),
            "imageToIOSIcons": BuiltinItemConfig(enabled: true, weight: 301, group: "Image"),
            "imageToMacIcons": BuiltinItemConfig(enabled: true, weight: 302, group: "Image"),
            "setCustomIcon": BuiltinItemConfig(enabled: true, weight: 303, group: "Image"),
            // Service
            "translateBaidu": BuiltinItemConfig(enabled: true, weight: 400, group: "Service"),
            "translateGoogle": BuiltinItemConfig(enabled: true, weight: 401, group: "Service"),
            "toQRCode": BuiltinItemConfig(enabled: true, weight: 402, group: "Service"),
            // iShot
            "iShotScreenshot": BuiltinItemConfig(enabled: true, weight: 500, group: "iShot"),
            "iShotAnnotate": BuiltinItemConfig(enabled: true, weight: 501, group: "iShot"),
        ],
        customScripts: [],
        templates: FileTemplate.defaultTemplates,
        favoriteFolders: [],
        favoriteDirectories: FavoriteDirectory.defaultDirectories,
        settings: AppSettings()
    )
}
