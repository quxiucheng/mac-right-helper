import Foundation

struct FavoriteDirectory: Codable, Identifiable {
    let id: String
    var name: String
    var path: String

    static let defaultDirectories: [FavoriteDirectory] = [
        FavoriteDirectory(id: "dir-desktop", name: "Desktop", path: "~/Desktop"),
        FavoriteDirectory(id: "dir-documents", name: "Documents", path: "~/Documents"),
        FavoriteDirectory(id: "dir-downloads", name: "Downloads", path: "~/Downloads"),
        FavoriteDirectory(id: "dir-home", name: "Home", path: "~"),
    ]
}
