import Foundation

enum TerminalOpenMode: String, Codable {
    case newWindow, newTab
}

struct AppSettings: Codable {
    var hideStatusBarIcon: Bool
    var terminalOpenMode: TerminalOpenMode
    var trashConfirm: Bool
    var cutHideFiles: Bool
    var defaultEditor: String
    var fullDiskAccessPrompted: Bool

    init(
        hideStatusBarIcon: Bool = false,
        terminalOpenMode: TerminalOpenMode = .newWindow,
        trashConfirm: Bool = true,
        cutHideFiles: Bool = false,
        defaultEditor: String = "com.microsoft.VSCode",
        fullDiskAccessPrompted: Bool = false
    ) {
        self.hideStatusBarIcon = hideStatusBarIcon
        self.terminalOpenMode = terminalOpenMode
        self.trashConfirm = trashConfirm
        self.cutHideFiles = cutHideFiles
        self.defaultEditor = defaultEditor
        self.fullDiskAccessPrompted = fullDiskAccessPrompted
    }
}
