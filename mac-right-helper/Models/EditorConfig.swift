import Foundation

struct EditorConfig: Codable, Identifiable {
    let id: String
    let name: String
    let bundleID: String
    let supportsOpenMode: Bool
}

extension EditorConfig {
    static let allEditors: [EditorConfig] = [
        EditorConfig(id: "vscode", name: "Visual Studio Code", bundleID: "com.microsoft.VSCode", supportsOpenMode: false),
        EditorConfig(id: "sublime", name: "Sublime Text", bundleID: "com.sublimetext.4", supportsOpenMode: false),
        EditorConfig(id: "sublime-merge", name: "Sublime Merge", bundleID: "com.sublimemerge", supportsOpenMode: false),
        EditorConfig(id: "warp", name: "Warp", bundleID: "dev.warp.Warp-Stable", supportsOpenMode: false),
        EditorConfig(id: "marktext", name: "MarkText", bundleID: "com.github.marktext", supportsOpenMode: false),
        EditorConfig(id: "obsidian", name: "Obsidian", bundleID: "md.obsidian", supportsOpenMode: false),
        EditorConfig(id: "tabby", name: "Tabby", bundleID: "org.tabby", supportsOpenMode: false),
        EditorConfig(id: "visualstudio", name: "Visual Studio", bundleID: "com.microsoft.visual-studio", supportsOpenMode: false),
        EditorConfig(id: "hyper", name: "Hyper", bundleID: "co.zeit.hyper", supportsOpenMode: false),
        EditorConfig(id: "emacs", name: "Emacs", bundleID: "org.gnu.Emacs", supportsOpenMode: false),
        EditorConfig(id: "clion", name: "CLion", bundleID: "com.jetbrains.CLion", supportsOpenMode: false),
        EditorConfig(id: "coteditor", name: "CotEditor", bundleID: "com.coteditor.CotEditor", supportsOpenMode: false),
        EditorConfig(id: "hbuilderx", name: "HBuilderX", bundleID: "io.dcloud.HBuilderX", supportsOpenMode: false),
        EditorConfig(id: "phpstorm", name: "PhpStorm", bundleID: "com.jetbrains.PhpStorm", supportsOpenMode: false),
        EditorConfig(id: "pycharm", name: "PyCharm", bundleID: "com.jetbrains.pycharm", supportsOpenMode: false),
        EditorConfig(id: "typora", name: "Typora", bundleID: "abnerworks.Typora", supportsOpenMode: false),
        EditorConfig(id: "webstorm", name: "WebStorm", bundleID: "com.jetbrains.WebStorm", supportsOpenMode: false),
        EditorConfig(id: "idea", name: "IntelliJ IDEA", bundleID: "com.jetbrains.intellij.ce", supportsOpenMode: false),
        EditorConfig(id: "android-studio", name: "Android Studio", bundleID: "com.google.android.studio", supportsOpenMode: false),
        EditorConfig(id: "appcode", name: "AppCode", bundleID: "com.jetbrains.AppCode", supportsOpenMode: false),
        EditorConfig(id: "datagrip", name: "DataGrip", bundleID: "com.jetbrains.DataGrip", supportsOpenMode: false),
        EditorConfig(id: "goland", name: "GoLand", bundleID: "com.jetbrains.goland", supportsOpenMode: false),
        EditorConfig(id: "rider", name: "Rider", bundleID: "com.jetbrains.rider", supportsOpenMode: false),
        EditorConfig(id: "rubymine", name: "RubyMine", bundleID: "com.jetbrains.rubymine", supportsOpenMode: false),
        EditorConfig(id: "terminal", name: "Terminal", bundleID: "com.apple.Terminal", supportsOpenMode: true),
        EditorConfig(id: "iterm2", name: "iTerm2", bundleID: "com.googlecode.iterm2", supportsOpenMode: true),
    ]
}
