import Foundation

/// Payload sent between main app and Finder Sync Extension
struct MessagePayload: Codable {
    var action: String = ""
    var target: [String] = []
    var rid: String = ""
    var trigger: String = ""
    /// Optional JSON-encoded [ActionItem] carried in config sync messages
    var configJSON: String? = nil

    var description: String {
        "MessagePayload(action: \(action), target: \(target), rid: \(rid), trigger: \(trigger))"
    }

    /// Parse configJSON to [ActionItem] array
    func parseActions() -> [ActionItem] {
        guard let json = configJSON,
              let data = json.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([ActionItem].self, from: data)) ?? []
    }
}

/// Action definition sent from main app to extension for menu building
struct ActionItem: Codable {
    let id: String
    let name: String
    let icon: String
    let group: String
    let enabled: Bool
}

/// Key constants shared between app and extension
enum MsgKey {
    static let fromFinder = "RClickHelperFromFinder"
    static let running = "RClickHelperRunning"
    static let quit = "RClickHelperQuit"
}

/// IPC messenger using DistributedNotificationCenter
class Messager {
    static let shared = Messager()

    private let center = DistributedNotificationCenter.default()
    private var handlers: [String: (MessagePayload) -> Void] = [:]

    init() {}

    func sendMessage(name: String, data: MessagePayload) {
        guard let json = encode(data) else { return }
        center.postNotificationName(
            NSNotification.Name(name),
            object: json,
            userInfo: nil,
            deliverImmediately: true
        )
    }

    func on(name: String, handler: @escaping (MessagePayload) -> Void) {
        center.addObserver(
            self,
            selector: #selector(received(_:)),
            name: NSNotification.Name(name),
            object: nil
        )
        handlers[name] = handler
    }

    @objc private func received(_ notification: NSNotification) {
        guard let json = notification.object as? String,
              let payload = decode(json) else { return }
        handlers[notification.name.rawValue]?(payload)
    }

    private func encode(_ payload: MessagePayload) -> String? {
        guard let data = try? JSONEncoder().encode(payload) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func decode(_ json: String) -> MessagePayload? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(MessagePayload.self, from: data)
    }
}
