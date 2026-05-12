import Foundation

struct MenuItem: Codable, Identifiable {
    let id: String
    let displayName: String
    let group: MenuGroup
    let icon: String?
    let sendTypes: [String]
    let action: MenuAction
    var isEnabled: Bool
    var sortWeight: Int
}
