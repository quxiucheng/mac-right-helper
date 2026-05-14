import Foundation
import AppKit

enum TranslationHelper {
    static func translateBaidu(text: String) {
        let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let url = URL(string: "https://fanyi.baidu.com/#auto/zh/\(encoded)")!
        NSWorkspace.shared.open(url)
    }

    static func translateGoogle(text: String) {
        let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let url = URL(string: "https://translate.google.com/?sl=auto&tl=zh-CN&text=\(encoded)")!
        NSWorkspace.shared.open(url)
    }
}
