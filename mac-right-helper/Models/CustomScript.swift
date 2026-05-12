import Foundation

enum ScriptType: String, Codable {
    case shell, python, appleScript
}

struct CustomScript: Codable, Identifiable {
    let id: String
    let name: String
    let type: ScriptType
    let source: String
    let icon: String?
    let sendTypes: [String]
    var sortWeight: Int
}
