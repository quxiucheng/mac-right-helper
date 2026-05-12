import Foundation

enum MenuGroup: String, Codable, CaseIterable {
    case fileOperations = "fileOperations"
    case devTools = "devTools"
    case systemEnhancements = "systemEnhancements"
    case customScripts = "customScripts"

    var displayName: String {
        switch self {
        case .fileOperations: return "File Operations"
        case .devTools: return "Dev Tools"
        case .systemEnhancements: return "System"
        case .customScripts: return "Custom Scripts"
        }
    }
}
