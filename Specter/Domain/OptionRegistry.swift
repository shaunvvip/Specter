import Foundation

struct OptionRegistry {
    let entries: [OptionEntry]
    let curated: Set<String>

    private let byKey: [String: OptionEntry]

    init(entries: [OptionEntry], curated: Set<String>) {
        self.entries = entries
        self.curated = curated
        self.byKey = Dictionary(uniqueKeysWithValues: entries.map { ($0.key, $0) })
    }

    func find(_ key: String) -> OptionEntry? {
        byKey[key]
    }

    func search(_ query: String) -> [OptionEntry] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return entries }
        return entries.filter {
            $0.key.lowercased().contains(q) ||
            $0.docMarkdown.lowercased().contains(q) ||
            $0.category.displayName.lowercased().contains(q)
        }
    }

    var curatedEntries: [OptionEntry] {
        entries.filter { curated.contains($0.key) }
    }
}
