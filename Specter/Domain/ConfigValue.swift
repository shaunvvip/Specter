import Foundation

enum ConfigValue: Equatable, Hashable {
    case string(String)
    case integer(Int)
    case double(Double)
    case bool(Bool)
    case opaque(String)

    var stringRepresentation: String {
        switch self {
        case .string(let s): return s
        case .integer(let i): return String(i)
        case .double(let d): return String(d)
        case .bool(let b): return b ? "true" : "false"
        case .opaque(let s): return s
        }
    }

    static func parse(_ raw: String, as type: OptionType) -> ConfigValue? {
        switch type {
        case .string, .color, .font, .theme, .keybind:
            return .string(raw)
        case .integer(let range):
            guard let i = Int(raw), range.contains(i) else { return nil }
            return .integer(i)
        case .double(let range):
            guard let d = Double(raw), range.contains(d) else { return nil }
            return .double(d)
        case .bool:
            if raw == "true" { return .bool(true) }
            if raw == "false" { return .bool(false) }
            return nil
        case .enumeration(let cases):
            return cases.contains(raw) ? .string(raw) : nil
        case .opaque:
            return .opaque(raw)
        }
    }
}
