import Foundation
import Observation

@Observable
final class ConfigModel {
    private(set) var values: [String: ConfigValue]
    private var applied: [String: ConfigValue]

    init(initialValues: [String: ConfigValue]) {
        self.values = initialValues
        self.applied = initialValues
    }

    var dirtyKeys: Set<String> {
        var keys = Set<String>()
        for (k, v) in values where applied[k] != v {
            keys.insert(k)
        }
        for k in applied.keys where values[k] == nil {
            keys.insert(k)
        }
        return keys
    }

    func set(_ key: String, _ value: ConfigValue) {
        values[key] = value
    }

    func reset(_ key: String) {
        if let original = applied[key] {
            values[key] = original
        } else {
            values.removeValue(forKey: key)
        }
    }

    func commit() {
        applied = values
    }

    /// Read access to the last-applied (disk-synced) value for a key. nil = the
    /// key was never present on disk → "Apply" will append it.
    func appliedValue(for key: String) -> ConfigValue? {
        applied[key]
    }

    // MARK: - Typed accessors
    // Avoid repeating `if case .string(let s) = ...` in every OptionRow.
    // Falls back to the OptionEntry default when the key isn't set, then to
    // the caller-provided default.

    func string(for key: String, default def: String = "") -> String {
        if case .string(let s) = values[key] { return s }
        return def
    }

    func integer(for key: String, default def: Int = 0) -> Int {
        if case .integer(let i) = values[key] { return i }
        return def
    }

    func double(for key: String, default def: Double = 0) -> Double {
        if case .double(let d) = values[key] { return d }
        return def
    }

    func bool(for key: String, default def: Bool = false) -> Bool {
        if case .bool(let b) = values[key] { return b }
        return def
    }
}
