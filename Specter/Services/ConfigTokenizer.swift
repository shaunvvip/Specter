import Foundation

enum ConfigTokenizer {
    static func tokenize(_ source: String) -> [ConfigToken] {
        guard !source.isEmpty else { return [] }
        return source.split(omittingEmptySubsequences: false, whereSeparator: { $0 == "\n" })
            .map { String($0) }
            .enumerated()
            .compactMap { idx, line in
                // Drop the synthetic trailing empty after a final newline so round-trip stays clean.
                if idx == source.split(omittingEmptySubsequences: false, whereSeparator: { $0 == "\n" }).count - 1
                    && line.isEmpty && source.hasSuffix("\n") { return nil }
                return tokenizeLine(line)
            }
    }

    private static func tokenizeLine(_ line: String) -> ConfigToken {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return .blank }
        if trimmed.hasPrefix("#") { return .comment(line) }
        guard let eqIdx = line.firstIndex(of: "=") else {
            return .malformed(line)
        }
        let key = String(line[..<eqIdx]).trimmingCharacters(in: .whitespaces)
        let raw = String(line[line.index(after: eqIdx)...]).trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else { return .malformed(line) }
        return .entry(key: key, raw: raw, recognized: true)
    }

    static func serialize(
        _ tokens: [ConfigToken],
        patching patches: [String: ConfigValue] = [:],
        appending newKeys: [String: ConfigValue] = [:]
    ) -> String {
        var lines: [String] = []
        var seenKeys = Set<String>()

        for token in tokens {
            switch token {
            case .comment(let s):       lines.append(s)
            case .blank:                lines.append("")
            case .malformed(let s):     lines.append(s)
            case .entry(let key, let raw, _):
                seenKeys.insert(key)
                if let newVal = patches[key] {
                    lines.append("\(key) = \(newVal.stringRepresentation)")
                } else {
                    lines.append("\(key) = \(raw)")
                }
            }
        }

        let toAppend = newKeys.filter { !seenKeys.contains($0.key) }
        if !toAppend.isEmpty {
            if !lines.isEmpty && !(lines.last?.isEmpty ?? false) { lines.append("") }
            lines.append("# Added by Specter")
            for (k, v) in toAppend.sorted(by: { $0.key < $1.key }) {
                lines.append("\(k) = \(v.stringRepresentation)")
            }
        }

        return lines.joined(separator: "\n") + "\n"
    }
}
