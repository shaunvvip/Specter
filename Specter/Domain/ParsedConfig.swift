import Foundation

struct ParsedConfig: Equatable {
    let tokens: [ConfigToken]
    let values: [String: ConfigValue]
    let mtime: Date

    static let empty = ParsedConfig(tokens: [], values: [:], mtime: .distantPast)
}
