import Foundation
import CommonCrypto

enum FileHasher {
    enum HashAlgorithm {
        case md5, sha1, sha256, sha512

        var digestLength: Int32 {
            switch self {
            case .md5: return CC_MD5_DIGEST_LENGTH
            case .sha1: return CC_SHA1_DIGEST_LENGTH
            case .sha256: return CC_SHA256_DIGEST_LENGTH
            case .sha512: return CC_SHA512_DIGEST_LENGTH
            }
        }

        func hash(data: Data) -> String {
            switch self {
            case .md5: return hashWith(data: data, function: CC_MD5, length: CC_MD5_DIGEST_LENGTH)
            case .sha1: return hashWith(data: data, function: CC_SHA1, length: CC_SHA1_DIGEST_LENGTH)
            case .sha256: return hashWith(data: data, function: CC_SHA256, length: CC_SHA256_DIGEST_LENGTH)
            case .sha512: return hashWith(data: data, function: CC_SHA512, length: CC_SHA512_DIGEST_LENGTH)
            }
        }

        private func hashWith<T>(data: Data, function: (UnsafeRawPointer, CC_LONG, UnsafeMutablePointer<UInt8>) -> T, length: Int32) -> String {
            var digest = [UInt8](repeating: 0, count: Int(length))
            _ = data.withUnsafeBytes { bytes in
                function(bytes.baseAddress!, CC_LONG(data.count), &digest)
            }
            return digest.map { String(format: "%02x", $0) }.joined()
        }
    }

    static func hash(filePath: String, algorithm: HashAlgorithm) throws -> String {
        let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
        return algorithm.hash(data: data)
    }
}
