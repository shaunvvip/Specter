import Foundation

enum ConfigToken: Equatable {
    case comment(String)
    case blank
    case entry(key: String, raw: String, recognized: Bool)
    case malformed(String)
}
