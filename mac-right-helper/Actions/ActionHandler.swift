import Foundation

protocol ActionHandler {
    func handle(filePaths: [String]) async throws
}
