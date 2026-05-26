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
}
