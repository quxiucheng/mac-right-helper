import Foundation

class ConfigManager {
    static let shared = ConfigManager()
    static let configKey = "RightHelperMenuConfig"
    static let configChangedNotification = Notification.Name("RightHelperConfigChanged")

    var config: AppConfig {
        didSet {
            NotificationCenter.default.post(name: Self.configChangedNotification, object: nil)
        }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.configKey),
           let decoded = try? JSONDecoder().decode(AppConfig.self, from: data) {
            self.config = decoded
        } else {
            self.config = AppConfig.defaultConfig
            save()
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: Self.configKey)
        }
    }

    func resetToDefaults() {
        config = AppConfig.defaultConfig
        save()
    }
}
