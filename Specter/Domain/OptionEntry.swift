import Foundation

struct OptionEntry: Identifiable, Hashable {
    let key: String
    let type: OptionType
    let defaultValue: ConfigValue
    let docMarkdown: String
    let category: SettingCategory
    let isCurated: Bool

    var id: String { key }

    func validate(_ value: ConfigValue) -> Bool {
        ConfigValue.parse(value.stringRepresentation, as: type) != nil
    }

    static func == (lhs: OptionEntry, rhs: OptionEntry) -> Bool {
        lhs.key == rhs.key
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }
}
