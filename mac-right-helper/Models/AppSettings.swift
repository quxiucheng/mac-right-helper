import Foundation

enum TerminalOpenMode: String, Codable {
    case newWindow, newTab
}

enum AppLanguage: String, Codable {
    case chinese = "zh"
    case english = "en"
}

struct AppSettings: Codable {
    var hideStatusBarIcon: Bool
    var terminalOpenMode: TerminalOpenMode
    var trashConfirm: Bool
    var cutHideFiles: Bool
    var defaultEditor: String
    var fullDiskAccessPrompted: Bool
    var language: AppLanguage

    init(
        hideStatusBarIcon: Bool = false,
        terminalOpenMode: TerminalOpenMode = .newWindow,
        trashConfirm: Bool = true,
        cutHideFiles: Bool = false,
        defaultEditor: String = "com.microsoft.VSCode",
        fullDiskAccessPrompted: Bool = false,
        language: AppLanguage = .chinese
    ) {
        self.hideStatusBarIcon = hideStatusBarIcon
        self.terminalOpenMode = terminalOpenMode
        self.trashConfirm = trashConfirm
        self.cutHideFiles = cutHideFiles
        self.defaultEditor = defaultEditor
        self.fullDiskAccessPrompted = fullDiskAccessPrompted
        self.language = language
    }
}
