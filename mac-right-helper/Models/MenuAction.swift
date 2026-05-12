import Foundation

enum MenuAction: Codable {
    case copyPath(format: PathFormat)
    case copyFileName
    case newFile(template: String)
    case compress
    case decompress
    case moveTo
    case copyTo
    case openInVSCode
    case openInTerminal
    case gitInit
    case gitStatus
    case formatJSON
    case toggleHiddenFiles
    case changePermissions
    case createSymlink
    case openParentDirectory
    case runCustomScript(id: String)

    enum PathFormat: String, Codable {
        case posix, hfs, url
    }
}
