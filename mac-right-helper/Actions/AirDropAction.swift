import Foundation

struct AirDropAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard !filePaths.isEmpty else { return }
        AirDropHelper.share(files: filePaths)
    }
}
