import Foundation

struct FavoriteFolder: Codable, Identifiable {
    let id: String
    var name: String
    var path: String
}
