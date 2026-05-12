import Foundation

struct AppConfig: Codable {
    var version: Int
    var builtinItems: [String: BuiltinItemConfig]
    var customScripts: [CustomScript]

    struct BuiltinItemConfig: Codable {
        var enabled: Bool
        var weight: Int
    }

    static let defaultConfig: AppConfig = AppConfig(
        version: 1,
        builtinItems: [
            "copyPath": BuiltinItemConfig(enabled: true, weight: 10),
            "copyFileName": BuiltinItemConfig(enabled: true, weight: 11),
            "newFile": BuiltinItemConfig(enabled: true, weight: 20),
            "compress": BuiltinItemConfig(enabled: true, weight: 30),
            "decompress": BuiltinItemConfig(enabled: true, weight: 31),
            "moveTo": BuiltinItemConfig(enabled: true, weight: 40),
            "copyTo": BuiltinItemConfig(enabled: true, weight: 41),
            "openInVSCode": BuiltinItemConfig(enabled: true, weight: 100),
            "openInTerminal": BuiltinItemConfig(enabled: true, weight: 101),
            "gitInit": BuiltinItemConfig(enabled: true, weight: 110),
            "gitStatus": BuiltinItemConfig(enabled: true, weight: 111),
            "formatJSON": BuiltinItemConfig(enabled: true, weight: 120),
            "toggleHiddenFiles": BuiltinItemConfig(enabled: true, weight: 200),
            "changePermissions": BuiltinItemConfig(enabled: true, weight: 201),
            "createSymlink": BuiltinItemConfig(enabled: true, weight: 202),
            "openParentDirectory": BuiltinItemConfig(enabled: true, weight: 203),
        ],
        customScripts: []
    )
}
