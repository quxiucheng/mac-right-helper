import Foundation

class ConfigManager {
    static let shared = ConfigManager()
    static let configKey = "RightHelperMenuConfig"
    static let configChangedNotification = Notification.Name("RightHelperConfigChanged")

    var config: AppConfig

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.configKey),
           let decoded = try? JSONDecoder().decode(AppConfig.self, from: data),
           decoded.version >= AppConfig.defaultConfig.version {
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
        NotificationCenter.default.post(name: Self.configChangedNotification, object: nil)
    }

    func resetToDefaults() {
        config = AppConfig.defaultConfig
        save()
    }
}
