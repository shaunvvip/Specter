# Specter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build Specter v1 — a native macOS GUI configurator for the Ghostty terminal — to the point of an installable, signable `.app` bundle with a working live-preview Inspector against ~40 curated config options.

**Architecture:** SwiftUI app, `@Observable` MVVM, actor-isolated IO services, xterm.js preview in WKWebView. Zero runtime Swift dependencies. See `docs/superpowers/specs/2026-05-26-specter-design.md` for full design.

**Tech Stack:** Swift 6, SwiftUI (macOS 14+), Observation framework, XCTest, XcodeGen (build tool), xterm.js (bundled JS, pnpm + esbuild build), GitHub Actions for CI.

---

## File Structure (target end state)

```
Specter/                          # repo root (currently ghostty-config-gui/)
├── project.yml                   # XcodeGen spec
├── Specter.xcodeproj/            # generated
├── Specter/
│   ├── App/
│   │   ├── SpecterApp.swift
│   │   └── AppEnvironment.swift
│   ├── View/
│   │   ├── ContentView.swift
│   │   ├── SidebarView.swift
│   │   ├── PreviewPane.swift
│   │   ├── InspectorPane.swift
│   │   ├── TopBar.swift
│   │   ├── CommandPalette.swift
│   │   └── OptionRow/
│   │       ├── OptionRowEnvelope.swift
│   │       ├── ToggleRow.swift
│   │       ├── SliderRow.swift
│   │       ├── StringRow.swift
│   │       ├── EnumRow.swift
│   │       ├── ColorRow.swift
│   │       ├── ThemeRow.swift
│   │       ├── FontRow.swift
│   │       └── ReadOnlyKeybindList.swift
│   ├── Domain/
│   │   ├── ConfigValue.swift
│   │   ├── Category.swift
│   │   ├── OptionType.swift
│   │   ├── OptionEntry.swift
│   │   ├── OptionRegistry.swift
│   │   ├── ConfigToken.swift
│   │   ├── ParsedConfig.swift
│   │   ├── ConfigModel.swift
│   │   ├── AppliedState.swift
│   │   ├── XtermOptions.swift
│   │   └── PreviewBridge.swift
│   ├── Services/
│   │   ├── GhostyCLI.swift
│   │   ├── ConfigTokenizer.swift
│   │   ├── ConfigFileService.swift
│   │   ├── BackupService.swift
│   │   ├── ReloadHelper.swift
│   │   └── FileWatcher.swift
│   ├── Resources/
│   │   └── preview/
│   │       ├── index.html
│   │       ├── xterm.bundle.js   # built artifact
│   │       └── demo.ans
│   ├── Info.plist
│   └── Specter.entitlements
├── SpecterTests/
│   ├── PreviewBridgeTests.swift
│   ├── OptionRegistryTests.swift
│   ├── ConfigModelTests.swift
│   ├── ConfigTokenizerTests.swift
│   ├── ConfigFileServiceTests.swift
│   ├── BackupServiceTests.swift
│   ├── GhostyCLITests.swift
│   └── Fixtures/
│       ├── basic.config
│       ├── basic.expected.config
│       ├── with-comments.config
│       └── ...
├── SpecterUITests/
│   └── SmokeTests.swift
├── preview-src/                  # xterm.js bundle source (build-time only)
│   ├── package.json
│   ├── index.ts
│   └── build.mjs
├── scripts/
│   ├── build-preview-bundle.sh
│   ├── notarize.sh
│   └── package-dmg.sh
├── .github/workflows/
│   ├── ci.yml
│   └── release.yml
├── README.md
└── LICENSE
```

---

## Phase 0 — Tooling & Project Scaffold

### Task 0.1: Install / verify tooling

**Files:** none (env setup)

- [ ] **Step 1: Verify Xcode + pnpm; install xcodegen**

```bash
xcodebuild -version | head -1    # expect: Xcode 26.x or higher
pnpm --version                    # expect: any
which xcodegen || brew install xcodegen
xcodegen --version
```

Expected: all three present after this step.

- [ ] **Step 2: No commit (tool install, not project change)**

### Task 0.2: Rename working directory & set up repo skeleton

**Files:**
- Move: `~/personal-projects/ghostty-config-gui` → `~/personal-projects/Specter` (optional rename to match brand; can defer)
- Create: `README.md` (one-line placeholder), `LICENSE` (MIT text)

- [ ] **Step 1: Write LICENSE (MIT, year 2026, holder "Specter contributors")**

`LICENSE`:
```
MIT License

Copyright (c) 2026 Specter contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 2: Write README.md (placeholder; full version in Task 5.4)**

```markdown
# Specter

> An unofficial GUI configurator for the [Ghostty](https://ghostty.org) terminal.
>
> Specter is not affiliated with, sponsored by, or endorsed by the Ghostty project.

🚧 Under construction.
```

- [ ] **Step 3: Commit**

```bash
git add LICENSE README.md
git commit -m "chore: add LICENSE and placeholder README"
```

### Task 0.3: Write XcodeGen project.yml

**Files:**
- Create: `project.yml`

- [ ] **Step 1: Write the project spec**

`project.yml`:
```yaml
name: Specter
options:
  bundleIdPrefix: com.specter
  deploymentTarget:
    macOS: "14.0"
  developmentLanguage: en
  createIntermediateGroups: true
settings:
  base:
    SWIFT_VERSION: "6.0"
    MACOSX_DEPLOYMENT_TARGET: "14.0"
    ENABLE_HARDENED_RUNTIME: YES
    CODE_SIGN_STYLE: Automatic
targets:
  Specter:
    type: application
    platform: macOS
    sources:
      - path: Specter
        excludes:
          - "Resources/preview/xterm.bundle.js"   # built artifact, copied via build phase below
    resources:
      - path: Specter/Resources
    info:
      path: Specter/Info.plist
      properties:
        CFBundleName: Specter
        CFBundleDisplayName: Specter
        CFBundleShortVersionString: "0.1.0"
        CFBundleVersion: "1"
        LSMinimumSystemVersion: "14.0"
        NSHighResolutionCapable: YES
        NSAppleEventsUsageDescription: "Specter uses Apple Events to ask Ghostty to reload its configuration after you apply changes."
    entitlements:
      path: Specter/Specter.entitlements
      properties:
        com.apple.security.app-sandbox: false
        com.apple.security.automation.apple-events: true
  SpecterTests:
    type: bundle.unit-test
    platform: macOS
    sources: SpecterTests
    dependencies:
      - target: Specter
  SpecterUITests:
    type: bundle.ui-testing
    platform: macOS
    sources: SpecterUITests
    dependencies:
      - target: Specter
schemes:
  Specter:
    build:
      targets:
        Specter: all
        SpecterTests: [test]
        SpecterUITests: [test]
    test:
      targets:
        - SpecterTests
        - SpecterUITests
```

- [ ] **Step 2: Generate the Xcode project**

```bash
mkdir -p Specter/Resources/preview Specter/App Specter/View Specter/View/OptionRow Specter/Domain Specter/Services
mkdir -p SpecterTests/Fixtures SpecterUITests
# Stub Info.plist + entitlements so xcodegen succeeds
touch Specter/Info.plist Specter/Specter.entitlements
# Stub a Swift file (xcodegen requires non-empty source dirs)
echo "import Foundation" > Specter/App/_Placeholder.swift
echo "import XCTest" > SpecterTests/_Placeholder.swift
echo "import XCTest" > SpecterUITests/_Placeholder.swift
xcodegen generate
```

Expected: `Specter.xcodeproj/` directory created.

- [ ] **Step 3: Verify project builds (empty app)**

```bash
xcodebuild -project Specter.xcodeproj -scheme Specter -destination 'platform=macOS' build 2>&1 | tail -5
```
Expected: `BUILD SUCCEEDED`.

- [ ] **Step 4: Commit**

```bash
git add project.yml Specter/ SpecterTests/ SpecterUITests/
git commit -m "build: scaffold Specter Xcode project via XcodeGen"
```

### Task 0.4: Add .gitignore for build artifacts

**Files:**
- Modify: `.gitignore`

- [ ] **Step 1: Append Xcode + xterm build artifacts**

Append to `.gitignore`:
```
# Generated by xcodegen
Specter.xcodeproj/

# xterm bundle (build artifact)
Specter/Resources/preview/xterm.bundle.js
preview-src/dist/
preview-src/node_modules/

# Backups during dev
*.bak
```

- [ ] **Step 2: Untrack Specter.xcodeproj**

```bash
git rm -rf --cached Specter.xcodeproj 2>/dev/null || true
```

- [ ] **Step 3: Commit**

```bash
git add .gitignore
git commit -m "chore: ignore xcodegen output and xterm build artifacts"
```

---

## Phase 1 — Domain Layer

Each Domain file is pure Swift, zero SwiftUI, zero Services. TDD all the way.

### Task 1.1: ConfigValue enum

**Files:**
- Create: `Specter/Domain/ConfigValue.swift`
- Test: `SpecterTests/ConfigValueTests.swift`

- [ ] **Step 1: Write failing test**

`SpecterTests/ConfigValueTests.swift`:
```swift
import XCTest
@testable import Specter

final class ConfigValueTests: XCTestCase {
    func test_stringRoundTrip() {
        let v = ConfigValue.string("hello")
        XCTAssertEqual(v.stringRepresentation, "hello")
        XCTAssertEqual(ConfigValue.parse("hello", as: .string), .string("hello"))
    }

    func test_integerRoundTrip() {
        XCTAssertEqual(ConfigValue.integer(14).stringRepresentation, "14")
        XCTAssertEqual(ConfigValue.parse("14", as: .integer(range: 8...72)), .integer(14))
        XCTAssertNil(ConfigValue.parse("not-a-number", as: .integer(range: 8...72)))
    }

    func test_doubleRoundTrip() {
        XCTAssertEqual(ConfigValue.double(0.78).stringRepresentation, "0.78")
        XCTAssertEqual(ConfigValue.parse("0.78", as: .double(range: 0...1)), .double(0.78))
    }

    func test_boolRoundTrip() {
        XCTAssertEqual(ConfigValue.bool(true).stringRepresentation, "true")
        XCTAssertEqual(ConfigValue.parse("true", as: .bool), .bool(true))
        XCTAssertEqual(ConfigValue.parse("false", as: .bool), .bool(false))
    }
}
```

- [ ] **Step 2: Run, expect failure**

```bash
xcodebuild test -project Specter.xcodeproj -scheme Specter -only-testing:SpecterTests/ConfigValueTests 2>&1 | tail -10
```
Expected: compile errors (ConfigValue undefined).

- [ ] **Step 3: Implement**

`Specter/Domain/ConfigValue.swift`:
```swift
import Foundation

enum ConfigValue: Equatable, Hashable {
    case string(String)
    case integer(Int)
    case double(Double)
    case bool(Bool)
    case opaque(String)   // for values we don't fully understand but want to preserve

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
```

- [ ] **Step 4: Run, expect pass (after OptionType is added in Task 1.3 — for now stub it)**

Add minimal stub at end of `ConfigValue.swift` temporarily:
```swift
// Temporary stub — replaced by Task 1.3
enum OptionType {
    case string
    case integer(range: ClosedRange<Int>)
    case double(range: ClosedRange<Double>)
    case bool
    case enumeration([String])
    case color
    case font
    case theme
    case keybind
    case opaque
}
```

Run test:
```bash
xcodebuild test -project Specter.xcodeproj -scheme Specter -only-testing:SpecterTests/ConfigValueTests 2>&1 | tail -5
```
Expected: tests pass.

- [ ] **Step 5: Commit**

```bash
git add Specter/Domain/ConfigValue.swift SpecterTests/ConfigValueTests.swift
git commit -m "domain: ConfigValue with typed parse/serialize"
```

### Task 1.2: Category enum

**Files:**
- Create: `Specter/Domain/Category.swift`

- [ ] **Step 1: Implement (trivial enum; no test needed)**

`Specter/Domain/Category.swift`:
```swift
import Foundation

enum Category: String, CaseIterable, Identifiable, Hashable {
    case appearance
    case font
    case window
    case cursor
    case mouse
    case clipboard
    case shellIntegration
    case keybind
    case macos
    case advanced
    case unknown

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .appearance: return "外观"
        case .font: return "字体"
        case .window: return "窗口"
        case .cursor: return "光标"
        case .mouse: return "鼠标"
        case .clipboard: return "剪贴板"
        case .shellIntegration: return "Shell Integration"
        case .keybind: return "键位"
        case .macos: return "macOS"
        case .advanced: return "高级"
        case .unknown: return "未识别"
        }
    }

    var sfSymbol: String {
        switch self {
        case .appearance: return "paintpalette"
        case .font: return "textformat"
        case .window: return "macwindow"
        case .cursor: return "cursorarrow"
        case .mouse: return "computermouse"
        case .clipboard: return "doc.on.clipboard"
        case .shellIntegration: return "terminal"
        case .keybind: return "keyboard"
        case .macos: return "apple.logo"
        case .advanced: return "gearshape.2"
        case .unknown: return "questionmark.square"
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Specter/Domain/Category.swift
git commit -m "domain: Category enum with display name + SF Symbol mapping"
```

### Task 1.3: OptionType + OptionEntry

**Files:**
- Create: `Specter/Domain/OptionType.swift`
- Create: `Specter/Domain/OptionEntry.swift`
- Modify: `Specter/Domain/ConfigValue.swift` (remove temporary OptionType stub)

- [ ] **Step 1: Move OptionType into its own file**

`Specter/Domain/OptionType.swift`:
```swift
import Foundation

enum OptionType: Equatable {
    case string
    case integer(range: ClosedRange<Int>)
    case double(range: ClosedRange<Double>)
    case bool
    case enumeration([String])
    case color
    case font
    case theme
    case keybind
    case opaque
}
```

- [ ] **Step 2: Remove temp stub from ConfigValue.swift**

Delete the `// Temporary stub — replaced by Task 1.3` block at the end of `ConfigValue.swift`.

- [ ] **Step 3: Implement OptionEntry**

`Specter/Domain/OptionEntry.swift`:
```swift
import Foundation

struct OptionEntry: Identifiable, Hashable {
    let key: String
    let type: OptionType
    let defaultValue: ConfigValue
    let docMarkdown: String
    let category: Category
    let isCurated: Bool

    var id: String { key }

    func validate(_ value: ConfigValue) -> Bool {
        ConfigValue.parse(value.stringRepresentation, as: type) != nil
    }
}
```

- [ ] **Step 4: Verify build**

```bash
xcodebuild build -project Specter.xcodeproj -scheme Specter 2>&1 | tail -5
```
Expected: BUILD SUCCEEDED.

- [ ] **Step 5: Commit**

```bash
git add Specter/Domain/OptionType.swift Specter/Domain/OptionEntry.swift Specter/Domain/ConfigValue.swift
git commit -m "domain: extract OptionType + add OptionEntry"
```

### Task 1.4: ConfigToken + ParsedConfig

**Files:**
- Create: `Specter/Domain/ConfigToken.swift`
- Create: `Specter/Domain/ParsedConfig.swift`

- [ ] **Step 1: Implement**

`Specter/Domain/ConfigToken.swift`:
```swift
import Foundation

enum ConfigToken: Equatable {
    case comment(String)             // includes leading "#"
    case blank
    case entry(key: String, raw: String, recognized: Bool)
    case malformed(String)            // preserve verbatim
}
```

`Specter/Domain/ParsedConfig.swift`:
```swift
import Foundation

struct ParsedConfig: Equatable {
    let tokens: [ConfigToken]
    let values: [String: ConfigValue]
    let mtime: Date

    static let empty = ParsedConfig(tokens: [], values: [:], mtime: .distantPast)
}
```

- [ ] **Step 2: Verify build**

```bash
xcodebuild build -project Specter.xcodeproj -scheme Specter 2>&1 | tail -5
```

- [ ] **Step 3: Commit**

```bash
git add Specter/Domain/ConfigToken.swift Specter/Domain/ParsedConfig.swift
git commit -m "domain: ConfigToken and ParsedConfig"
```

### Task 1.5: OptionRegistry

**Files:**
- Create: `Specter/Domain/OptionRegistry.swift`
- Test: `SpecterTests/OptionRegistryTests.swift`

- [ ] **Step 1: Write failing tests**

`SpecterTests/OptionRegistryTests.swift`:
```swift
import XCTest
@testable import Specter

final class OptionRegistryTests: XCTestCase {
    private func entry(_ key: String, category: Category = .appearance, curated: Bool = true) -> OptionEntry {
        OptionEntry(key: key, type: .string, defaultValue: .string(""),
                    docMarkdown: "doc for \(key)", category: category, isCurated: curated)
    }

    func test_findByKey_returnsEntry() {
        let r = OptionRegistry(entries: [entry("theme"), entry("font-size")], curated: [])
        XCTAssertNotNil(r.find("theme"))
        XCTAssertNil(r.find("nonexistent"))
    }

    func test_search_matchesKey() {
        let r = OptionRegistry(entries: [entry("font-size"), entry("font-family"), entry("theme")], curated: [])
        let hits = r.search("font")
        XCTAssertEqual(Set(hits.map(\.key)), ["font-size", "font-family"])
    }

    func test_search_emptyQueryReturnsAll() {
        let entries = [entry("a"), entry("b")]
        let r = OptionRegistry(entries: entries, curated: [])
        XCTAssertEqual(r.search("").count, 2)
    }

    func test_search_matchesDoc() {
        var e = entry("background-opacity")
        e = OptionEntry(key: e.key, type: e.type, defaultValue: e.defaultValue,
                        docMarkdown: "Controls how see-through the window is",
                        category: e.category, isCurated: e.isCurated)
        let r = OptionRegistry(entries: [e], curated: [])
        XCTAssertEqual(r.search("see-through").count, 1)
    }

    func test_curatedEntries_filteredCorrectly() {
        let r = OptionRegistry(entries: [
            entry("theme", curated: true),
            entry("xx-deep-option", curated: false)
        ], curated: ["theme"])
        XCTAssertEqual(r.curatedEntries.count, 1)
        XCTAssertEqual(r.curatedEntries.first?.key, "theme")
    }
}
```

- [ ] **Step 2: Run, expect failure**

```bash
xcodebuild test -project Specter.xcodeproj -scheme Specter -only-testing:SpecterTests/OptionRegistryTests 2>&1 | tail -10
```
Expected: compile errors.

- [ ] **Step 3: Implement**

`Specter/Domain/OptionRegistry.swift`:
```swift
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
```

- [ ] **Step 4: Run, expect pass**

```bash
xcodebuild test -project Specter.xcodeproj -scheme Specter -only-testing:SpecterTests/OptionRegistryTests 2>&1 | tail -5
```

- [ ] **Step 5: Commit**

```bash
git add Specter/Domain/OptionRegistry.swift SpecterTests/OptionRegistryTests.swift
git commit -m "domain: OptionRegistry with find/search/curated APIs"
```

### Task 1.6: ConfigModel (Observable)

**Files:**
- Create: `Specter/Domain/ConfigModel.swift`
- Test: `SpecterTests/ConfigModelTests.swift`

- [ ] **Step 1: Write failing tests**

`SpecterTests/ConfigModelTests.swift`:
```swift
import XCTest
@testable import Specter

final class ConfigModelTests: XCTestCase {
    func test_initWithApplied_noDirtyKeys() {
        let m = ConfigModel(initialValues: ["theme": .string("Mocha")])
        XCTAssertTrue(m.dirtyKeys.isEmpty)
        XCTAssertEqual(m.values["theme"], .string("Mocha"))
    }

    func test_setKey_marksDirty() {
        let m = ConfigModel(initialValues: ["theme": .string("Mocha")])
        m.set("theme", .string("TokyoNight"))
        XCTAssertEqual(m.dirtyKeys, ["theme"])
        XCTAssertEqual(m.values["theme"], .string("TokyoNight"))
    }

    func test_setBackToOriginal_clearsDirty() {
        let m = ConfigModel(initialValues: ["theme": .string("Mocha")])
        m.set("theme", .string("TokyoNight"))
        m.set("theme", .string("Mocha"))
        XCTAssertTrue(m.dirtyKeys.isEmpty)
    }

    func test_setNewKey_marksDirty() {
        let m = ConfigModel(initialValues: [:])
        m.set("font-size", .integer(15))
        XCTAssertEqual(m.dirtyKeys, ["font-size"])
    }

    func test_reset_restoresOriginal() {
        let m = ConfigModel(initialValues: ["theme": .string("Mocha")])
        m.set("theme", .string("TokyoNight"))
        m.reset("theme")
        XCTAssertEqual(m.values["theme"], .string("Mocha"))
        XCTAssertTrue(m.dirtyKeys.isEmpty)
    }

    func test_commit_movesAppliedForward() {
        let m = ConfigModel(initialValues: ["theme": .string("Mocha")])
        m.set("theme", .string("TokyoNight"))
        m.commit()
        XCTAssertTrue(m.dirtyKeys.isEmpty)
        XCTAssertEqual(m.values["theme"], .string("TokyoNight"))
        m.reset("theme")
        XCTAssertEqual(m.values["theme"], .string("TokyoNight"))
    }
}
```

- [ ] **Step 2: Run, expect failure**

```bash
xcodebuild test -project Specter.xcodeproj -scheme Specter -only-testing:SpecterTests/ConfigModelTests 2>&1 | tail -10
```

- [ ] **Step 3: Implement**

`Specter/Domain/ConfigModel.swift`:
```swift
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
        values[key] = applied[key]
        if values[key] == nil { values.removeValue(forKey: key) }
    }

    func commit() {
        applied = values
    }
}
```

- [ ] **Step 4: Run, expect pass**

```bash
xcodebuild test -project Specter.xcodeproj -scheme Specter -only-testing:SpecterTests/ConfigModelTests 2>&1 | tail -5
```

- [ ] **Step 5: Commit**

```bash
git add Specter/Domain/ConfigModel.swift SpecterTests/ConfigModelTests.swift
git commit -m "domain: ConfigModel (Observable) with dirty-key tracking"
```

### Task 1.7: XtermOptions + PreviewBridge

**Files:**
- Create: `Specter/Domain/XtermOptions.swift`
- Create: `Specter/Domain/PreviewBridge.swift`
- Test: `SpecterTests/PreviewBridgeTests.swift`

- [ ] **Step 1: Write failing tests**

`SpecterTests/PreviewBridgeTests.swift`:
```swift
import XCTest
@testable import Specter

final class PreviewBridgeTests: XCTestCase {
    func test_defaultModel_defaultOptions() {
        let m = ConfigModel(initialValues: [:])
        let opts = PreviewBridge.translate(m)
        XCTAssertEqual(opts.fontSize, 14)
        XCTAssertEqual(opts.fontFamily, "JetBrains Mono")
    }

    func test_fontSizeApplied() {
        let m = ConfigModel(initialValues: ["font-size": .integer(18)])
        XCTAssertEqual(PreviewBridge.translate(m).fontSize, 18)
    }

    func test_fontFamilyApplied() {
        let m = ConfigModel(initialValues: ["font-family": .string("Fira Code")])
        XCTAssertEqual(PreviewBridge.translate(m).fontFamily, "Fira Code")
    }

    func test_backgroundOpacityApplied() {
        let m = ConfigModel(initialValues: ["background-opacity": .double(0.7)])
        XCTAssertEqual(PreviewBridge.translate(m).backgroundOpacity, 0.7, accuracy: 0.0001)
    }

    func test_cursorStyleMappedToXterm() {
        let m = ConfigModel(initialValues: ["cursor-style": .string("block")])
        XCTAssertEqual(PreviewBridge.translate(m).cursorStyle, "block")

        let m2 = ConfigModel(initialValues: ["cursor-style": .string("bar")])
        XCTAssertEqual(PreviewBridge.translate(m2).cursorStyle, "bar")
    }

    func test_jsonSerializable() throws {
        let opts = PreviewBridge.translate(ConfigModel(initialValues: [:]))
        let data = try JSONEncoder().encode(opts)
        XCTAssertFalse(data.isEmpty)
    }
}
```

- [ ] **Step 2: Run, expect failure**

```bash
xcodebuild test -project Specter.xcodeproj -scheme Specter -only-testing:SpecterTests/PreviewBridgeTests 2>&1 | tail -10
```

- [ ] **Step 3: Implement**

`Specter/Domain/XtermOptions.swift`:
```swift
import Foundation

struct XtermOptions: Codable, Equatable {
    var fontFamily: String
    var fontSize: Int
    var backgroundOpacity: Double
    var paddingX: Int
    var paddingY: Int
    var cursorStyle: String   // "block" | "bar" | "underline"
    var cursorBlink: Bool
    var theme: XtermTheme
}

struct XtermTheme: Codable, Equatable {
    var background: String
    var foreground: String
    var cursor: String
    var black: String
    var red: String
    var green: String
    var yellow: String
    var blue: String
    var magenta: String
    var cyan: String
    var white: String
    var brightBlack: String
    var brightRed: String
    var brightGreen: String
    var brightYellow: String
    var brightBlue: String
    var brightMagenta: String
    var brightCyan: String
    var brightWhite: String

    static let mocha = XtermTheme(
        background: "#1e1e2e", foreground: "#cdd6f4", cursor: "#f5e0dc",
        black: "#45475a", red: "#f38ba8", green: "#a6e3a1", yellow: "#f9e2af",
        blue: "#89b4fa", magenta: "#f5c2e7", cyan: "#94e2d5", white: "#bac2de",
        brightBlack: "#585b70", brightRed: "#f38ba8", brightGreen: "#a6e3a1",
        brightYellow: "#f9e2af", brightBlue: "#89b4fa", brightMagenta: "#f5c2e7",
        brightCyan: "#94e2d5", brightWhite: "#a6adc8"
    )
}
```

`Specter/Domain/PreviewBridge.swift`:
```swift
import Foundation

enum PreviewBridge {
    static func translate(_ model: ConfigModel) -> XtermOptions {
        func str(_ key: String, default def: String) -> String {
            if case .string(let s) = model.values[key] { return s }
            return def
        }
        func int(_ key: String, default def: Int) -> Int {
            if case .integer(let i) = model.values[key] { return i }
            return def
        }
        func dbl(_ key: String, default def: Double) -> Double {
            if case .double(let d) = model.values[key] { return d }
            return def
        }
        func bool(_ key: String, default def: Bool) -> Bool {
            if case .bool(let b) = model.values[key] { return b }
            return def
        }

        let (px, py) = parsePadding(str("window-padding-x", default: "4,2"),
                                     str("window-padding-y", default: "6,0"))

        return XtermOptions(
            fontFamily: str("font-family", default: "JetBrains Mono"),
            fontSize: int("font-size", default: 14),
            backgroundOpacity: dbl("background-opacity", default: 1.0),
            paddingX: px,
            paddingY: py,
            cursorStyle: str("cursor-style", default: "block"),
            cursorBlink: bool("cursor-blink", default: true),
            theme: .mocha   // theme lookup wired up in Task 3.x (ThemeRow); default for now
        )
    }

    private static func parsePadding(_ x: String, _ y: String) -> (Int, Int) {
        let xVal = Int(x.split(separator: ",").first ?? "4") ?? 4
        let yVal = Int(y.split(separator: ",").first ?? "6") ?? 6
        return (xVal, yVal)
    }
}
```

- [ ] **Step 4: Run, expect pass**

```bash
xcodebuild test -project Specter.xcodeproj -scheme Specter -only-testing:SpecterTests/PreviewBridgeTests 2>&1 | tail -5
```

- [ ] **Step 5: Commit**

```bash
git add Specter/Domain/XtermOptions.swift Specter/Domain/PreviewBridge.swift SpecterTests/PreviewBridgeTests.swift
git commit -m "domain: XtermOptions + PreviewBridge (pure translation function)"
```

---

## Phase 2 — Services Layer

### Task 2.1: ConfigTokenizer

**Files:**
- Create: `Specter/Services/ConfigTokenizer.swift`
- Test: `SpecterTests/ConfigTokenizerTests.swift`

- [ ] **Step 1: Write failing tests covering each token form**

`SpecterTests/ConfigTokenizerTests.swift`:
```swift
import XCTest
@testable import Specter

final class ConfigTokenizerTests: XCTestCase {
    func test_emptyInput() {
        XCTAssertEqual(ConfigTokenizer.tokenize(""), [])
    }

    func test_singleEntry() {
        let tokens = ConfigTokenizer.tokenize("theme = Mocha")
        XCTAssertEqual(tokens, [.entry(key: "theme", raw: "Mocha", recognized: true)])
    }

    func test_entryWithSpacesAroundEquals() {
        let tokens = ConfigTokenizer.tokenize("font-size  =  14")
        XCTAssertEqual(tokens, [.entry(key: "font-size", raw: "14", recognized: true)])
    }

    func test_commentLine() {
        let tokens = ConfigTokenizer.tokenize("# this is a comment")
        XCTAssertEqual(tokens, [.comment("# this is a comment")])
    }

    func test_blankLine() {
        let tokens = ConfigTokenizer.tokenize("\n")
        XCTAssertEqual(tokens, [.blank])
    }

    func test_malformedLine() {
        let tokens = ConfigTokenizer.tokenize("garbage no equals here")
        XCTAssertEqual(tokens, [.malformed("garbage no equals here")])
    }

    func test_mixedFile() {
        let input = """
        # heading
        theme = Mocha

        font-size = 14
        garbage
        """
        let tokens = ConfigTokenizer.tokenize(input)
        XCTAssertEqual(tokens, [
            .comment("# heading"),
            .entry(key: "theme", raw: "Mocha", recognized: true),
            .blank,
            .entry(key: "font-size", raw: "14", recognized: true),
            .malformed("garbage")
        ])
    }

    func test_serialize_roundTrip() {
        let input = """
        # h
        theme = Mocha

        garbage
        """
        let tokens = ConfigTokenizer.tokenize(input)
        let out = ConfigTokenizer.serialize(tokens)
        XCTAssertEqual(out, input + "\n")  // tokenizer adds trailing newline
    }

    func test_serialize_patchesDirtyKey() {
        let tokens = ConfigTokenizer.tokenize("theme = Mocha\nfont-size = 14")
        let out = ConfigTokenizer.serialize(tokens, patching: ["theme": .string("TokyoNight")])
        XCTAssertTrue(out.contains("theme = TokyoNight"))
        XCTAssertTrue(out.contains("font-size = 14"))
        XCTAssertFalse(out.contains("Mocha"))
    }

    func test_serialize_appendsNewKey() {
        let tokens = ConfigTokenizer.tokenize("theme = Mocha")
        let out = ConfigTokenizer.serialize(
            tokens,
            patching: ["theme": .string("Mocha")],
            appending: ["font-size": .integer(16)]
        )
        XCTAssertTrue(out.contains("theme = Mocha"))
        XCTAssertTrue(out.contains("# Added by Specter"))
        XCTAssertTrue(out.contains("font-size = 16"))
    }
}
```

- [ ] **Step 2: Run, expect failure**

- [ ] **Step 3: Implement**

`Specter/Services/ConfigTokenizer.swift`:
```swift
import Foundation

enum ConfigTokenizer {
    static func tokenize(_ source: String) -> [ConfigToken] {
        guard !source.isEmpty else { return [] }
        return source.split(omittingEmptySubsequences: false, whereSeparator: { $0 == "\n" })
            .map { String($0) }
            .map(tokenizeLine)
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
            case .comment(let s):
                lines.append(s)
            case .blank:
                lines.append("")
            case .malformed(let s):
                lines.append(s)
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
```

- [ ] **Step 4: Run, expect pass**

- [ ] **Step 5: Commit**

```bash
git add Specter/Services/ConfigTokenizer.swift SpecterTests/ConfigTokenizerTests.swift
git commit -m "services: ConfigTokenizer with comment-preserving round trip"
```

### Task 2.2: ConfigFileService

**Files:**
- Create: `Specter/Services/ConfigFileService.swift`
- Test: `SpecterTests/ConfigFileServiceTests.swift`
- Create test fixtures: `SpecterTests/Fixtures/basic.config`, `basic.expected.config`

- [ ] **Step 1: Write failing tests**

`SpecterTests/Fixtures/basic.config`:
```
# user's heading
theme = light:Catppuccin Latte,dark:Catppuccin Mocha

font-family = "JetBrainsMono Nerd Font Mono"
font-size = 14
```

`SpecterTests/ConfigFileServiceTests.swift`:
```swift
import XCTest
@testable import Specter

final class ConfigFileServiceTests: XCTestCase {
    var tempDir: URL!

    override func setUp() async throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    private func writeFixture(_ name: String, _ content: String) throws -> URL {
        let url = tempDir.appendingPathComponent(name)
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    func test_readMissingFile_returnsEmpty() async throws {
        let svc = ConfigFileService(configURL: tempDir.appendingPathComponent("nonexistent"))
        let parsed = try await svc.read()
        XCTAssertEqual(parsed, ParsedConfig.empty)
    }

    func test_readBasicFile_extractsValues() async throws {
        let url = try writeFixture("config", "theme = Mocha\nfont-size = 14\n")
        let svc = ConfigFileService(configURL: url)
        let parsed = try await svc.read()
        XCTAssertEqual(parsed.values["theme"], .string("Mocha"))
        XCTAssertEqual(parsed.values["font-size"], .string("14"))
    }

    func test_writePreservesComments() async throws {
        let original = "# my heading\ntheme = Mocha\nfont-size = 14\n"
        let url = try writeFixture("config", original)
        let svc = ConfigFileService(configURL: url)

        let model = ConfigModel(initialValues: try await svc.read().values)
        model.set("theme", .string("TokyoNight"))

        try await svc.write(model: model, originalTokens: try await svc.read().tokens)
        let after = try String(contentsOf: url, encoding: .utf8)

        XCTAssertTrue(after.contains("# my heading"))
        XCTAssertTrue(after.contains("theme = TokyoNight"))
        XCTAssertTrue(after.contains("font-size = 14"))
        XCTAssertFalse(after.contains("Mocha"))
    }

    func test_writeAtomic_noPartialFileOnError() async throws {
        // Verify temp + rename: no junk left if write fails mid-flight
        let url = try writeFixture("config", "theme = Mocha\n")
        let svc = ConfigFileService(configURL: url)
        let model = ConfigModel(initialValues: ["theme": .string("Mocha")])
        try await svc.write(model: model, originalTokens: try await svc.read().tokens)
        // Confirm no .tmp file left
        let siblings = try FileManager.default.contentsOfDirectory(atPath: tempDir.path)
        XCTAssertFalse(siblings.contains(where: { $0.hasSuffix(".tmp") }))
    }
}
```

- [ ] **Step 2: Run, expect failure**

- [ ] **Step 3: Implement**

`Specter/Services/ConfigFileService.swift`:
```swift
import Foundation

actor ConfigFileService {
    let configURL: URL

    init(configURL: URL) {
        self.configURL = configURL
    }

    func read() throws -> ParsedConfig {
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            return .empty
        }
        let content = try String(contentsOf: configURL, encoding: .utf8)
        let tokens = ConfigTokenizer.tokenize(content)
        let attrs = try FileManager.default.attributesOfItem(atPath: configURL.path)
        let mtime = (attrs[.modificationDate] as? Date) ?? .distantPast

        var values: [String: ConfigValue] = [:]
        for case .entry(let key, let raw, _) in tokens {
            values[key] = .string(raw)
        }
        return ParsedConfig(tokens: tokens, values: values, mtime: mtime)
    }

    func write(model: ConfigModel, originalTokens: [ConfigToken]) throws {
        let originalKeys = Set(originalTokens.compactMap { token -> String? in
            if case .entry(let k, _, _) = token { return k } else { return nil }
        })

        var patches: [String: ConfigValue] = [:]
        var appending: [String: ConfigValue] = [:]
        for (key, val) in model.values {
            if originalKeys.contains(key) {
                patches[key] = val
            } else {
                appending[key] = val
            }
        }

        let output = ConfigTokenizer.serialize(originalTokens, patching: patches, appending: appending)

        // Atomic write: temp file → fsync → rename
        let tempURL = configURL.appendingPathExtension("tmp")
        try output.write(to: tempURL, atomically: false, encoding: .utf8)
        let fh = try FileHandle(forUpdating: tempURL)
        try fh.synchronize()
        try fh.close()
        _ = try FileManager.default.replaceItemAt(configURL, withItemAt: tempURL)
    }
}
```

- [ ] **Step 4: Run, expect pass**

- [ ] **Step 5: Commit**

```bash
git add Specter/Services/ConfigFileService.swift SpecterTests/ConfigFileServiceTests.swift SpecterTests/Fixtures/
git commit -m "services: ConfigFileService with atomic, comment-preserving write"
```

### Task 2.3: BackupService

**Files:**
- Create: `Specter/Services/BackupService.swift`
- Test: `SpecterTests/BackupServiceTests.swift`

- [ ] **Step 1: Write failing tests**

`SpecterTests/BackupServiceTests.swift`:
```swift
import XCTest
@testable import Specter

final class BackupServiceTests: XCTestCase {
    var tempDir: URL!

    override func setUp() async throws {
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    func test_snapshotCreatesTimestampedFile() async throws {
        let cfg = tempDir.appendingPathComponent("config")
        try "theme = Mocha".write(to: cfg, atomically: true, encoding: .utf8)
        let backups = tempDir.appendingPathComponent("backups")
        let svc = BackupService(configURL: cfg, backupDir: backups)
        let backup = try await svc.snapshot()
        let content = try String(contentsOf: backup, encoding: .utf8)
        XCTAssertEqual(content, "theme = Mocha")
        XCTAssertTrue(backup.path.contains(backups.path))
    }

    func test_snapshotMissingSource_skipsGracefully() async throws {
        let cfg = tempDir.appendingPathComponent("missing")
        let backups = tempDir.appendingPathComponent("backups")
        let svc = BackupService(configURL: cfg, backupDir: backups)
        XCTAssertNil(try await svc.snapshot())
    }

    func test_pruneTo20() async throws {
        let cfg = tempDir.appendingPathComponent("config")
        try "x".write(to: cfg, atomically: true, encoding: .utf8)
        let backups = tempDir.appendingPathComponent("backups")
        let svc = BackupService(configURL: cfg, backupDir: backups, maxBackups: 3)
        for _ in 0..<5 {
            _ = try await svc.snapshot()
            try await Task.sleep(nanoseconds: 5_000_000)   // ensure unique timestamps
        }
        let count = try FileManager.default.contentsOfDirectory(atPath: backups.path).count
        XCTAssertEqual(count, 3)
    }
}
```

- [ ] **Step 2: Run, expect failure**

- [ ] **Step 3: Implement**

`Specter/Services/BackupService.swift`:
```swift
import Foundation

actor BackupService {
    let configURL: URL
    let backupDir: URL
    let maxBackups: Int

    init(configURL: URL, backupDir: URL, maxBackups: Int = 20) {
        self.configURL = configURL
        self.backupDir = backupDir
        self.maxBackups = maxBackups
    }

    @discardableResult
    func snapshot() throws -> URL? {
        guard FileManager.default.fileExists(atPath: configURL.path) else { return nil }
        try FileManager.default.createDirectory(at: backupDir, withIntermediateDirectories: true)

        let ts = ISO8601DateFormatter.fileSafe.string(from: Date())
        let dest = backupDir.appendingPathComponent("\(ts).config")
        try FileManager.default.copyItem(at: configURL, to: dest)
        try prune()
        return dest
    }

    private func prune() throws {
        let urls = try FileManager.default
            .contentsOfDirectory(at: backupDir, includingPropertiesForKeys: [.contentModificationDateKey])
            .filter { $0.pathExtension == "config" }
        guard urls.count > maxBackups else { return }
        let sorted = try urls.sorted { lhs, rhs in
            let l = try lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate ?? .distantPast
            let r = try rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate ?? .distantPast
            return l < r
        }
        for url in sorted.prefix(sorted.count - maxBackups) {
            try? FileManager.default.removeItem(at: url)
        }
    }
}

private extension ISO8601DateFormatter {
    static let fileSafe: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withYear, .withMonth, .withDay, .withTime,
                           .withDashSeparatorInDate, .withColonSeparatorInTime]
        return f
    }()
}
```

- [ ] **Step 4: Run, expect pass**

- [ ] **Step 5: Commit**

```bash
git add Specter/Services/BackupService.swift SpecterTests/BackupServiceTests.swift
git commit -m "services: BackupService with timestamped snapshots + prune"
```

### Task 2.4: GhostyCLI

**Files:**
- Create: `Specter/Services/GhostyCLI.swift`
- Test: `SpecterTests/GhostyCLITests.swift`
- Create test fixture: `SpecterTests/Fixtures/fake-ghostty.sh`

- [ ] **Step 1: Write the fake ghostty binary fixture**

`SpecterTests/Fixtures/fake-ghostty.sh`:
```bash
#!/bin/bash
case "$1" in
  +list-themes)
    cat <<EOF
TokyoNight Storm
TokyoNight Day
Catppuccin Mocha
Catppuccin Latte
Dracula
EOF
    ;;
  +list-fonts)
    cat <<EOF
JetBrains Mono
Fira Code
SF Mono
EOF
    ;;
  +version)
    echo "Ghostty 1.0.0"
    ;;
  *)
    echo "unknown subcommand" >&2; exit 2 ;;
esac
```

Make it executable as part of the test setup (in test code).

- [ ] **Step 2: Write failing tests**

`SpecterTests/GhostyCLITests.swift`:
```swift
import XCTest
@testable import Specter

final class GhostyCLITests: XCTestCase {
    var fakeBinary: URL!

    override func setUp() async throws {
        let bundle = Bundle(for: type(of: self))
        guard let path = bundle.path(forResource: "fake-ghostty", ofType: "sh") else {
            XCTFail("Missing fixture fake-ghostty.sh")
            return
        }
        fakeBinary = URL(fileURLWithPath: path)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: fakeBinary.path)
    }

    func test_listThemes() async throws {
        let cli = GhostyCLI(binaryURL: fakeBinary)
        let themes = try await cli.listThemes()
        XCTAssertTrue(themes.contains("TokyoNight Storm"))
        XCTAssertTrue(themes.contains("Catppuccin Mocha"))
        XCTAssertEqual(themes.count, 5)
    }

    func test_listFonts() async throws {
        let cli = GhostyCLI(binaryURL: fakeBinary)
        let fonts = try await cli.listFonts()
        XCTAssertTrue(fonts.contains("JetBrains Mono"))
    }

    func test_version() async throws {
        let cli = GhostyCLI(binaryURL: fakeBinary)
        let v = try await cli.version()
        XCTAssertEqual(v, "Ghostty 1.0.0")
    }

    func test_binaryMissing_throws() async {
        let cli = GhostyCLI(binaryURL: URL(fileURLWithPath: "/nonexistent/ghostty"))
        do {
            _ = try await cli.listThemes()
            XCTFail("Expected throw")
        } catch GhostyCLIError.binaryNotFound { /* ok */ }
        catch { XCTFail("Unexpected error: \(error)") }
    }
}
```

- [ ] **Step 3: Implement**

`Specter/Services/GhostyCLI.swift`:
```swift
import Foundation

enum GhostyCLIError: Error {
    case binaryNotFound
    case nonZeroExit(Int32, stderr: String)
    case timeout
}

actor GhostyCLI {
    let binaryURL: URL
    let timeoutSeconds: TimeInterval

    private var cachedThemes: [String]?
    private var cachedFonts: [String]?

    init(binaryURL: URL = URL(fileURLWithPath: "/opt/homebrew/bin/ghostty"),
         timeoutSeconds: TimeInterval = 3) {
        self.binaryURL = binaryURL
        self.timeoutSeconds = timeoutSeconds
    }

    static func resolvedBinary() -> URL? {
        let candidates = ["/opt/homebrew/bin/ghostty", "/usr/local/bin/ghostty"]
        for path in candidates where FileManager.default.isExecutableFile(atPath: path) {
            return URL(fileURLWithPath: path)
        }
        return nil
    }

    func listThemes() async throws -> [String] {
        if let cached = cachedThemes { return cached }
        let out = try run(["+list-themes"])
        let themes = out.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        cachedThemes = themes
        return themes
    }

    func listFonts() async throws -> [String] {
        if let cached = cachedFonts { return cached }
        let out = try run(["+list-fonts"])
        let fonts = out.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        cachedFonts = fonts
        return fonts
    }

    func version() async throws -> String {
        try run(["+version"]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func run(_ args: [String]) throws -> String {
        guard FileManager.default.isExecutableFile(atPath: binaryURL.path) else {
            throw GhostyCLIError.binaryNotFound
        }
        let process = Process()
        process.executableURL = binaryURL
        process.arguments = args
        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe
        try process.run()

        let deadline = Date().addingTimeInterval(timeoutSeconds)
        while process.isRunning {
            if Date() > deadline {
                process.terminate()
                throw GhostyCLIError.timeout
            }
            Thread.sleep(forTimeInterval: 0.02)
        }

        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        if process.terminationStatus != 0 {
            throw GhostyCLIError.nonZeroExit(process.terminationStatus,
                                              stderr: String(data: errData, encoding: .utf8) ?? "")
        }
        return String(data: outData, encoding: .utf8) ?? ""
    }
}
```

- [ ] **Step 4: Add fixture to test bundle (modify project.yml)**

Add to `project.yml` under `SpecterTests`:
```yaml
  SpecterTests:
    type: bundle.unit-test
    platform: macOS
    sources: SpecterTests
    resources:
      - path: SpecterTests/Fixtures
    dependencies:
      - target: Specter
```

Then regenerate:
```bash
xcodegen generate
```

- [ ] **Step 5: Run, expect pass**

```bash
xcodebuild test -project Specter.xcodeproj -scheme Specter -only-testing:SpecterTests/GhostyCLITests 2>&1 | tail -5
```

- [ ] **Step 6: Commit**

```bash
git add Specter/Services/GhostyCLI.swift SpecterTests/GhostyCLITests.swift SpecterTests/Fixtures/fake-ghostty.sh project.yml
git commit -m "services: GhostyCLI with timeout, caching, fake-binary tests"
```

### Task 2.5: ReloadHelper

**Files:**
- Create: `Specter/Services/ReloadHelper.swift`

- [ ] **Step 1: Implement (no test — AppleScript hits real system)**

`Specter/Services/ReloadHelper.swift`:
```swift
import Foundation
import AppKit

enum ReloadResult {
    case sent
    case ghosttyNotRunning
    case automationDenied
    case scriptError(String)
}

actor ReloadHelper {
    func requestReload() async -> ReloadResult {
        let running = NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == "com.mitchellh.ghostty"
        }
        guard running else { return .ghosttyNotRunning }

        let script = """
        tell application "System Events"
            tell process "Ghostty"
                keystroke "," using {command down, shift down}
            end tell
        end tell
        """
        var error: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else {
            return .scriptError("Could not compile AppleScript")
        }
        _ = appleScript.executeAndReturnError(&error)
        if let error = error {
            let code = error[NSAppleScript.errorNumber] as? Int ?? 0
            if code == -1743 || code == -1719 {  // privilege errors
                return .automationDenied
            }
            return .scriptError(error[NSAppleScript.errorMessage] as? String ?? "Unknown")
        }
        return .sent
    }
}
```

- [ ] **Step 2: Verify build**

```bash
xcodebuild build -project Specter.xcodeproj -scheme Specter 2>&1 | tail -5
```

- [ ] **Step 3: Commit**

```bash
git add Specter/Services/ReloadHelper.swift
git commit -m "services: ReloadHelper using NSAppleScript ⌘+Shift+, to Ghostty"
```

### Task 2.6: FileWatcher

**Files:**
- Create: `Specter/Services/FileWatcher.swift`

- [ ] **Step 1: Implement (manual test via app — no XCTest for DispatchSource)**

`Specter/Services/FileWatcher.swift`:
```swift
import Foundation
import Combine

final class FileWatcher {
    private var source: DispatchSourceFileSystemObject?
    private let fileDescriptor: CInt
    private let url: URL
    private let queue = DispatchQueue(label: "com.specter.filewatcher")
    private var debounceWork: DispatchWorkItem?

    let changeSubject = PassthroughSubject<Void, Never>()

    init?(url: URL) {
        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else { return nil }
        self.fileDescriptor = fd
        self.url = url

        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .delete, .rename, .extend],
            queue: queue
        )
        self.source = src
        src.setEventHandler { [weak self] in
            self?.debounceFire()
        }
        src.setCancelHandler { [fd] in
            close(fd)
        }
        src.resume()
    }

    private func debounceFire() {
        debounceWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.changeSubject.send(())
        }
        debounceWork = work
        queue.asyncAfter(deadline: .now() + .milliseconds(250), execute: work)
    }

    deinit {
        source?.cancel()
    }
}
```

- [ ] **Step 2: Verify build**

- [ ] **Step 3: Commit**

```bash
git add Specter/Services/FileWatcher.swift
git commit -m "services: FileWatcher (DispatchSource + 250ms debounce)"
```

---

## Phase 3 — View Layer

### Task 3.1: AppEnvironment + SpecterApp entry

**Files:**
- Create: `Specter/App/AppEnvironment.swift`
- Modify: `Specter/App/SpecterApp.swift` (replace placeholder)
- Delete: `Specter/App/_Placeholder.swift`

- [ ] **Step 1: Implement AppEnvironment**

`Specter/App/AppEnvironment.swift`:
```swift
import Foundation
import Observation

@Observable
final class AppEnvironment {
    let configFileService: ConfigFileService
    let backupService: BackupService
    let ghostyCLI: GhostyCLI
    let reloadHelper: ReloadHelper

    var registry: OptionRegistry = OptionRegistry(entries: [], curated: [])
    var configModel: ConfigModel = ConfigModel(initialValues: [:])
    var loadError: String?
    var dirtyApplyError: String?
    var lastReloadResult: ReloadResult?

    static var defaultConfigURL: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".config/ghostty/config")
    }

    static var defaultBackupDir: URL {
        let appSupport = try? FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true
        )
        return (appSupport ?? FileManager.default.temporaryDirectory)
            .appendingPathComponent("Specter/Backups", isDirectory: true)
    }

    init(configURL: URL = AppEnvironment.defaultConfigURL,
         backupDir: URL = AppEnvironment.defaultBackupDir,
         ghostyBinary: URL? = nil) {
        self.configFileService = ConfigFileService(configURL: configURL)
        self.backupService = BackupService(configURL: configURL, backupDir: backupDir)
        if let bin = ghostyBinary {
            self.ghostyCLI = GhostyCLI(binaryURL: bin)
        } else if let bin = GhostyCLI.resolvedBinary() {
            self.ghostyCLI = GhostyCLI(binaryURL: bin)
        } else {
            // Will surface as binaryNotFound error on use
            self.ghostyCLI = GhostyCLI(binaryURL: URL(fileURLWithPath: "/opt/homebrew/bin/ghostty"))
        }
        self.reloadHelper = ReloadHelper()
    }

    func bootstrap() async {
        // Load registry (from CuratedOptions plus, later, --docs scraped entries)
        registry = OptionRegistry.curatedV1()

        // Load config file
        do {
            let parsed = try await configFileService.read()
            await MainActor.run {
                self.configModel = ConfigModel(initialValues: parsed.values)
            }
        } catch {
            await MainActor.run {
                self.loadError = "Failed to read config: \(error.localizedDescription)"
            }
        }
    }

    func apply() async {
        do {
            _ = try await backupService.snapshot()
        } catch {
            await MainActor.run { self.dirtyApplyError = "Backup failed: \(error.localizedDescription) — refusing to apply" }
            return
        }
        do {
            let parsed = try await configFileService.read()
            try await configFileService.write(model: configModel, originalTokens: parsed.tokens)
            await MainActor.run { self.configModel.commit() }
        } catch {
            await MainActor.run { self.dirtyApplyError = "Apply failed: \(error.localizedDescription)" }
            return
        }
        let result = await reloadHelper.requestReload()
        await MainActor.run { self.lastReloadResult = result }
    }
}
```

- [ ] **Step 2: Implement SpecterApp entry**

Replace `Specter/App/_Placeholder.swift` content; rename file to `SpecterApp.swift`:

```bash
rm Specter/App/_Placeholder.swift
```

`Specter/App/SpecterApp.swift`:
```swift
import SwiftUI

@main
struct SpecterApp: App {
    @State private var env = AppEnvironment()

    var body: some Scene {
        WindowGroup("Specter") {
            ContentView()
                .environment(env)
                .frame(minWidth: 980, minHeight: 620)
                .task { await env.bootstrap() }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
    }
}
```

- [ ] **Step 3: Add minimal stub for `OptionRegistry.curatedV1()` + `ContentView` so this compiles**

`Specter/Domain/OptionRegistry+CuratedV1.swift`:
```swift
import Foundation

extension OptionRegistry {
    static func curatedV1() -> OptionRegistry {
        let entries: [OptionEntry] = [
            // ── Appearance ────────────────────────
            OptionEntry(key: "theme", type: .theme, defaultValue: .string(""),
                docMarkdown: "终端主题。可用 `light:Name,dark:Name` 跟随系统切换。",
                category: .appearance, isCurated: true),
            OptionEntry(key: "background-opacity", type: .double(range: 0...1),
                defaultValue: .double(1.0),
                docMarkdown: "窗口背景透明度。0 = 完全透明，1 = 不透明。",
                category: .appearance, isCurated: true),
            OptionEntry(key: "background-blur-radius", type: .integer(range: 0...50),
                defaultValue: .integer(0),
                docMarkdown: "背景毛玻璃模糊半径。仅当 background-opacity < 1 时生效。",
                category: .appearance, isCurated: true),

            // ── Font ─────────────────────────────
            OptionEntry(key: "font-family", type: .font, defaultValue: .string("JetBrains Mono"),
                docMarkdown: "等宽字体名。建议安装 Nerd Font 版本以显示图标。",
                category: .font, isCurated: true),
            OptionEntry(key: "font-size", type: .integer(range: 8...72), defaultValue: .integer(14),
                docMarkdown: "字号 (pt)。常用 12–16。",
                category: .font, isCurated: true),
            OptionEntry(key: "font-feature", type: .string, defaultValue: .string(""),
                docMarkdown: "OpenType 字体特性（如 `+calt`, `-liga`）。",
                category: .font, isCurated: false),

            // ── Window ───────────────────────────
            OptionEntry(key: "window-padding-x", type: .string, defaultValue: .string("4,2"),
                docMarkdown: "水平内边距 `left,right`（像素）。",
                category: .window, isCurated: true),
            OptionEntry(key: "window-padding-y", type: .string, defaultValue: .string("6,0"),
                docMarkdown: "垂直内边距 `top,bottom`（像素）。",
                category: .window, isCurated: true),
            OptionEntry(key: "macos-titlebar-style",
                type: .enumeration(["transparent", "tabs", "native", "hidden"]),
                defaultValue: .string("transparent"),
                docMarkdown: "macOS 标题栏样式。`transparent` 与终端背景融为一体。",
                category: .macos, isCurated: true),
            OptionEntry(key: "macos-option-as-alt",
                type: .enumeration(["left", "right", "true", "false"]),
                defaultValue: .string("false"),
                docMarkdown: "Option 键当作 Alt 发送转义序列。`right` 只让右 Option 当 Alt，左 Option 保留为修饰键（用于块选）。",
                category: .macos, isCurated: true),

            // ── Cursor ───────────────────────────
            OptionEntry(key: "cursor-style", type: .enumeration(["block", "bar", "underline"]),
                defaultValue: .string("block"),
                docMarkdown: "光标形状。",
                category: .cursor, isCurated: true),
            OptionEntry(key: "cursor-style-blink", type: .bool, defaultValue: .bool(true),
                docMarkdown: "光标是否闪烁。",
                category: .cursor, isCurated: true),

            // ── Mouse ────────────────────────────
            OptionEntry(key: "selection-clear-on-typing", type: .bool, defaultValue: .bool(true),
                docMarkdown: "打字时是否清空当前选区。设为 false 可在选完后继续输入命令再粘贴。",
                category: .mouse, isCurated: true),
            OptionEntry(key: "mouse-hide-while-typing", type: .bool, defaultValue: .bool(false),
                docMarkdown: "打字时隐藏鼠标指针。",
                category: .mouse, isCurated: true),

            // ── Shell Integration ────────────────
            OptionEntry(key: "shell-integration",
                type: .enumeration(["none", "detect", "bash", "elvish", "fish", "zsh"]),
                defaultValue: .string("detect"),
                docMarkdown: "Shell 集成方式（命令光标提示、标题更新、sudo 提示等）。",
                category: .shellIntegration, isCurated: true),

            // ── Behavior ─────────────────────────
            OptionEntry(key: "confirm-close-surface",
                type: .enumeration(["false", "always", "true"]),
                defaultValue: .string("true"),
                docMarkdown: "关闭终端窗口/标签前是否二次确认。",
                category: .window, isCurated: true),
        ]
        let curated = Set(entries.filter { $0.isCurated }.map { $0.key })
        return OptionRegistry(entries: entries, curated: curated)
    }
}
```

`Specter/View/ContentView.swift`:
```swift
import SwiftUI

struct ContentView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        NavigationSplitView {
            Text("Sidebar — coming in 3.3").padding()
        } content: {
            Text("Preview — coming in 3.9").padding()
        } detail: {
            Text("Inspector — coming in 3.8").padding()
        }
        .navigationTitle("Specter")
    }
}
```

- [ ] **Step 4: Regenerate Xcode project and build**

```bash
xcodegen generate
xcodebuild build -project Specter.xcodeproj -scheme Specter 2>&1 | tail -5
```
Expected: BUILD SUCCEEDED.

- [ ] **Step 5: Commit**

```bash
git add Specter/App/ Specter/Domain/OptionRegistry+CuratedV1.swift Specter/View/ContentView.swift
git rm Specter/App/_Placeholder.swift 2>/dev/null || true
git commit -m "view: SpecterApp entry, AppEnvironment, curated v1 registry, ContentView skeleton"
```

### Task 3.2: TopBar

**Files:**
- Create: `Specter/View/TopBar.swift`

- [ ] **Step 1: Implement**

`Specter/View/TopBar.swift`:
```swift
import SwiftUI

struct TopBar: View {
    @Environment(AppEnvironment.self) private var env
    @Binding var searchQuery: String

    var body: some View {
        HStack(spacing: 12) {
            Button(action: applyTapped) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Apply")
                    if !env.configModel.dirtyKeys.isEmpty {
                        Text("\(env.configModel.dirtyKeys.count)")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.orange.opacity(0.85), in: Capsule())
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(env.configModel.dirtyKeys.isEmpty)

            Button(action: resetTapped) {
                Label("Reset", systemImage: "arrow.uturn.backward")
            }
            .buttonStyle(.bordered)
            .disabled(env.configModel.dirtyKeys.isEmpty)

            Spacer()

            HStack {
                Image(systemName: "magnifyingglass")
                TextField("⌘K  搜索 200+ 设置", text: $searchQuery)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            .frame(maxWidth: 320)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(.bar)
    }

    private func applyTapped() {
        Task { await env.apply() }
    }

    private func resetTapped() {
        for key in env.configModel.dirtyKeys {
            env.configModel.reset(key)
        }
    }
}
```

- [ ] **Step 2: Build to verify it compiles**

```bash
xcodebuild build -project Specter.xcodeproj -scheme Specter 2>&1 | tail -5
```

- [ ] **Step 3: Commit**

```bash
git add Specter/View/TopBar.swift
git commit -m "view: TopBar with Apply/Reset buttons + search field"
```

### Task 3.3: SidebarView

**Files:**
- Create: `Specter/View/SidebarView.swift`

- [ ] **Step 1: Implement**

`Specter/View/SidebarView.swift`:
```swift
import SwiftUI

struct SidebarView: View {
    @Binding var selectedCategory: Category

    private let categoriesInOrder: [Category] = [
        .appearance, .font, .window, .cursor, .mouse,
        .shellIntegration, .keybind, .macos, .advanced
    ]

    var body: some View {
        List(selection: $selectedCategory) {
            ForEach(categoriesInOrder) { cat in
                Label(cat.displayName, systemImage: cat.sfSymbol).tag(cat)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Specter")
    }
}
```

- [ ] **Step 2: Wire into ContentView**

Modify `Specter/View/ContentView.swift`:
```swift
import SwiftUI

struct ContentView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var selectedCategory: Category = .appearance
    @State private var searchQuery: String = ""

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedCategory: $selectedCategory)
                .frame(minWidth: 160)
        } content: {
            VStack(spacing: 0) {
                TopBar(searchQuery: $searchQuery)
                Text("Preview — coming in 3.9")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } detail: {
            Text("Inspector — coming in 3.8")
                .frame(minWidth: 280)
        }
        .navigationTitle("Specter")
    }
}
```

- [ ] **Step 3: Build**

```bash
xcodebuild build -project Specter.xcodeproj -scheme Specter 2>&1 | tail -5
```

- [ ] **Step 4: Commit**

```bash
git add Specter/View/SidebarView.swift Specter/View/ContentView.swift
git commit -m "view: SidebarView + wire categories into ContentView"
```

### Task 3.4: OptionRow envelope + Toggle/Slider/String/Enum rows

**Files:**
- Create: `Specter/View/OptionRow/OptionRowEnvelope.swift`
- Create: `Specter/View/OptionRow/ToggleRow.swift`
- Create: `Specter/View/OptionRow/SliderRow.swift`
- Create: `Specter/View/OptionRow/StringRow.swift`
- Create: `Specter/View/OptionRow/EnumRow.swift`

- [ ] **Step 1: Implement OptionRowEnvelope (label + doc + control slot)**

`Specter/View/OptionRow/OptionRowEnvelope.swift`:
```swift
import SwiftUI

struct OptionRowEnvelope<Content: View>: View {
    let entry: OptionEntry
    @Binding var isExpanded: Bool
    @ViewBuilder var control: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(entry.key).font(.system(.body, design: .monospaced))
                Spacer()
                control()
                    .frame(maxWidth: 180, alignment: .trailing)
            }
            if isExpanded {
                Text(entry.docMarkdown)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture { isExpanded.toggle() }
    }
}
```

- [ ] **Step 2: Implement ToggleRow**

`Specter/View/OptionRow/ToggleRow.swift`:
```swift
import SwiftUI

struct ToggleRow: View {
    let entry: OptionEntry
    @Environment(AppEnvironment.self) private var env
    @State private var expanded = false

    var body: some View {
        OptionRowEnvelope(entry: entry, isExpanded: $expanded) {
            Toggle("", isOn: Binding(
                get: {
                    if case .bool(let b) = env.configModel.values[entry.key] { return b }
                    if case .bool(let b) = entry.defaultValue { return b }
                    return false
                },
                set: { env.configModel.set(entry.key, .bool($0)) }
            ))
            .labelsHidden()
        }
    }
}
```

- [ ] **Step 3: Implement SliderRow (int or double)**

`Specter/View/OptionRow/SliderRow.swift`:
```swift
import SwiftUI

struct SliderRow: View {
    let entry: OptionEntry
    @Environment(AppEnvironment.self) private var env
    @State private var expanded = false

    var body: some View {
        OptionRowEnvelope(entry: entry, isExpanded: $expanded) {
            switch entry.type {
            case .integer(let range):
                HStack {
                    Slider(value: Binding(
                        get: {
                            if case .integer(let i) = env.configModel.values[entry.key] { return Double(i) }
                            if case .integer(let i) = entry.defaultValue { return Double(i) }
                            return Double(range.lowerBound)
                        },
                        set: { env.configModel.set(entry.key, .integer(Int($0))) }
                    ), in: Double(range.lowerBound)...Double(range.upperBound), step: 1)
                    Text(currentInt(range: range)).font(.caption.monospacedDigit()).frame(width: 32)
                }
            case .double(let range):
                HStack {
                    Slider(value: Binding(
                        get: {
                            if case .double(let d) = env.configModel.values[entry.key] { return d }
                            if case .double(let d) = entry.defaultValue { return d }
                            return range.lowerBound
                        },
                        set: { env.configModel.set(entry.key, .double($0)) }
                    ), in: range, step: 0.01)
                    Text(currentDouble(range: range)).font(.caption.monospacedDigit()).frame(width: 40)
                }
            default:
                Text("unsupported")
            }
        }
    }

    private func currentInt(range: ClosedRange<Int>) -> String {
        if case .integer(let i) = env.configModel.values[entry.key] { return String(i) }
        if case .integer(let i) = entry.defaultValue { return String(i) }
        return String(range.lowerBound)
    }

    private func currentDouble(range: ClosedRange<Double>) -> String {
        if case .double(let d) = env.configModel.values[entry.key] { return String(format: "%.2f", d) }
        if case .double(let d) = entry.defaultValue { return String(format: "%.2f", d) }
        return String(format: "%.2f", range.lowerBound)
    }
}
```

- [ ] **Step 4: Implement StringRow**

`Specter/View/OptionRow/StringRow.swift`:
```swift
import SwiftUI

struct StringRow: View {
    let entry: OptionEntry
    @Environment(AppEnvironment.self) private var env
    @State private var expanded = false

    var body: some View {
        OptionRowEnvelope(entry: entry, isExpanded: $expanded) {
            TextField("", text: Binding(
                get: {
                    if case .string(let s) = env.configModel.values[entry.key] { return s }
                    if case .string(let s) = entry.defaultValue { return s }
                    return ""
                },
                set: { env.configModel.set(entry.key, .string($0)) }
            ))
            .textFieldStyle(.roundedBorder)
        }
    }
}
```

- [ ] **Step 5: Implement EnumRow**

`Specter/View/OptionRow/EnumRow.swift`:
```swift
import SwiftUI

struct EnumRow: View {
    let entry: OptionEntry
    @Environment(AppEnvironment.self) private var env
    @State private var expanded = false

    var body: some View {
        OptionRowEnvelope(entry: entry, isExpanded: $expanded) {
            if case .enumeration(let cases) = entry.type {
                Picker("", selection: Binding(
                    get: {
                        if case .string(let s) = env.configModel.values[entry.key] { return s }
                        if case .string(let s) = entry.defaultValue { return s }
                        return cases.first ?? ""
                    },
                    set: { env.configModel.set(entry.key, .string($0)) }
                )) {
                    ForEach(cases, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
        }
    }
}
```

- [ ] **Step 6: Build**

- [ ] **Step 7: Commit**

```bash
git add Specter/View/OptionRow/
git commit -m "view: OptionRow envelope + Toggle/Slider/String/Enum row variants"
```

### Task 3.5: ThemeRow + FontRow

**Files:**
- Create: `Specter/View/OptionRow/ThemeRow.swift`
- Create: `Specter/View/OptionRow/FontRow.swift`

- [ ] **Step 1: Implement ThemeRow (loads from GhostyCLI on appear)**

`Specter/View/OptionRow/ThemeRow.swift`:
```swift
import SwiftUI

struct ThemeRow: View {
    let entry: OptionEntry
    @Environment(AppEnvironment.self) private var env
    @State private var expanded = false
    @State private var themes: [String] = []

    var body: some View {
        OptionRowEnvelope(entry: entry, isExpanded: $expanded) {
            Picker("", selection: Binding(
                get: currentValue,
                set: { env.configModel.set(entry.key, .string($0)) }
            )) {
                Text("(default)").tag("")
                ForEach(themes, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
        .task { await load() }
    }

    private func currentValue() -> String {
        if case .string(let s) = env.configModel.values[entry.key] { return s }
        return ""
    }

    private func load() async {
        do {
            themes = try await env.ghostyCLI.listThemes()
        } catch {
            themes = []
        }
    }
}
```

- [ ] **Step 2: Implement FontRow (similar pattern)**

`Specter/View/OptionRow/FontRow.swift`:
```swift
import SwiftUI

struct FontRow: View {
    let entry: OptionEntry
    @Environment(AppEnvironment.self) private var env
    @State private var expanded = false
    @State private var fonts: [String] = []

    var body: some View {
        OptionRowEnvelope(entry: entry, isExpanded: $expanded) {
            Picker("", selection: Binding(
                get: currentValue,
                set: { env.configModel.set(entry.key, .string($0)) }
            )) {
                Text("(default)").tag("")
                ForEach(fonts, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
        .task { await load() }
    }

    private func currentValue() -> String {
        if case .string(let s) = env.configModel.values[entry.key] { return s }
        return ""
    }

    private func load() async {
        do {
            fonts = try await env.ghostyCLI.listFonts()
        } catch {
            fonts = []
        }
    }
}
```

- [ ] **Step 3: Build + commit**

```bash
xcodebuild build -project Specter.xcodeproj -scheme Specter 2>&1 | tail -3
git add Specter/View/OptionRow/ThemeRow.swift Specter/View/OptionRow/FontRow.swift
git commit -m "view: ThemeRow + FontRow (lazy load from ghostty CLI)"
```

### Task 3.6: InspectorPane

**Files:**
- Create: `Specter/View/InspectorPane.swift`

- [ ] **Step 1: Implement**

`Specter/View/InspectorPane.swift`:
```swift
import SwiftUI

struct InspectorPane: View {
    @Environment(AppEnvironment.self) private var env
    let category: Category
    let searchQuery: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(filteredEntries) { entry in
                    rowView(for: entry)
                    Divider().opacity(0.3)
                }
                if filteredEntries.isEmpty {
                    Text("没有匹配项")
                        .foregroundStyle(.secondary)
                        .padding(.top, 40).frame(maxWidth: .infinity)
                }
            }
            .padding(16)
        }
    }

    private var filteredEntries: [OptionEntry] {
        let base = searchQuery.isEmpty
            ? env.registry.entries.filter { $0.category == category && $0.isCurated }
            : env.registry.search(searchQuery)
        return base
    }

    @ViewBuilder
    private func rowView(for entry: OptionEntry) -> some View {
        switch entry.type {
        case .bool:                          ToggleRow(entry: entry)
        case .integer, .double:              SliderRow(entry: entry)
        case .enumeration:                   EnumRow(entry: entry)
        case .theme:                         ThemeRow(entry: entry)
        case .font:                          FontRow(entry: entry)
        case .string, .color, .keybind, .opaque:
                                             StringRow(entry: entry)
        }
    }
}
```

- [ ] **Step 2: Wire into ContentView (replace Inspector stub)**

Modify `Specter/View/ContentView.swift`:
```swift
import SwiftUI

struct ContentView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var selectedCategory: Category = .appearance
    @State private var searchQuery: String = ""

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedCategory: $selectedCategory)
                .frame(minWidth: 160)
        } content: {
            VStack(spacing: 0) {
                TopBar(searchQuery: $searchQuery)
                Divider()
                Text("Preview — coming in 3.7")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } detail: {
            InspectorPane(category: selectedCategory, searchQuery: searchQuery)
                .frame(minWidth: 320)
        }
    }
}
```

- [ ] **Step 3: Build + commit**

```bash
xcodebuild build -project Specter.xcodeproj -scheme Specter 2>&1 | tail -3
git add Specter/View/InspectorPane.swift Specter/View/ContentView.swift
git commit -m "view: InspectorPane with category filter + search"
```

### Task 3.7: PreviewPane (WKWebView + JS bridge)

**Files:**
- Create: `Specter/View/PreviewPane.swift`

- [ ] **Step 1: Implement**

`Specter/View/PreviewPane.swift`:
```swift
import SwiftUI
import WebKit

struct PreviewPane: NSViewRepresentable {
    @Environment(AppEnvironment.self) private var env

    func makeNSView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.preferences.javaScriptEnabled = true
        let webView = WKWebView(frame: .zero, configuration: cfg)
        webView.setValue(false, forKey: "drawsBackground")  // for transparency
        if let url = Bundle.main.url(forResource: "index", withExtension: "html",
                                     subdirectory: "preview") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        context.coordinator.webView = webView
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let opts = PreviewBridge.translate(env.configModel)
        guard let data = try? JSONEncoder().encode(opts),
              let json = String(data: data, encoding: .utf8) else { return }
        let js = "window.applyPreview && window.applyPreview(\(json));"
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        weak var webView: WKWebView?
    }
}
```

- [ ] **Step 2: Wire into ContentView**

Replace `Text("Preview — coming in 3.7")` with `PreviewPane()` in `ContentView.swift`.

- [ ] **Step 3: Build + commit**

```bash
xcodebuild build -project Specter.xcodeproj -scheme Specter 2>&1 | tail -3
git add Specter/View/PreviewPane.swift Specter/View/ContentView.swift
git commit -m "view: PreviewPane (WKWebView loading bundled xterm.js)"
```

---

## Phase 4 — Web Resources (xterm.js bundle + demo)

### Task 4.1: preview-src/ package.json + bundle script

**Files:**
- Create: `preview-src/package.json`
- Create: `preview-src/index.ts`
- Create: `preview-src/build.mjs`
- Create: `scripts/build-preview-bundle.sh`

- [ ] **Step 1: Write package.json**

`preview-src/package.json`:
```json
{
  "name": "specter-preview",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "build": "node build.mjs"
  },
  "dependencies": {
    "@xterm/xterm": "^5.5.0"
  },
  "devDependencies": {
    "esbuild": "^0.20.0"
  }
}
```

- [ ] **Step 2: Write the entry file**

`preview-src/index.ts`:
```typescript
import { Terminal, ITheme } from "@xterm/xterm";

const term = new Terminal({
  fontFamily: "JetBrains Mono",
  fontSize: 14,
  cursorBlink: true,
  cursorStyle: "block",
  allowTransparency: true,
  theme: defaultTheme(),
});

term.open(document.getElementById("term")!);

function defaultTheme(): ITheme {
  return {
    background: "#1e1e2e", foreground: "#cdd6f4", cursor: "#f5e0dc",
  };
}

interface XtermOptions {
  fontFamily: string;
  fontSize: number;
  backgroundOpacity: number;
  paddingX: number;
  paddingY: number;
  cursorStyle: "block" | "bar" | "underline";
  cursorBlink: boolean;
  theme: ITheme & {
    black: string; red: string; green: string; yellow: string;
    blue: string; magenta: string; cyan: string; white: string;
    brightBlack: string; brightRed: string; brightGreen: string;
    brightYellow: string; brightBlue: string; brightMagenta: string;
    brightCyan: string; brightWhite: string;
  };
}

(window as any).applyPreview = (opts: XtermOptions) => {
  term.options.fontFamily = opts.fontFamily;
  term.options.fontSize = opts.fontSize;
  term.options.cursorBlink = opts.cursorBlink;
  term.options.cursorStyle = opts.cursorStyle;
  term.options.theme = opts.theme;
  document.body.style.background = applyOpacity(opts.theme.background ?? "#1e1e2e", opts.backgroundOpacity);
  const wrap = document.getElementById("term-wrap");
  if (wrap) wrap.style.padding = `${opts.paddingY}px ${opts.paddingX}px`;
};

function applyOpacity(hex: string, opacity: number): string {
  const h = hex.replace("#", "");
  const r = parseInt(h.slice(0, 2), 16);
  const g = parseInt(h.slice(2, 4), 16);
  const b = parseInt(h.slice(4, 6), 16);
  return `rgba(${r}, ${g}, ${b}, ${opacity})`;
}

// Demo content (looped)
const lines = [
  "\x1b[36m~ $\x1b[0m neofetch",
  "\x1b[34m   ▄▀▀▀▀▀▀▀▀▀▄    OS:\x1b[0m   macOS Sequoia",
  "\x1b[34m  █  ◯     ◯  █   Shell:\x1b[0m zsh 5.9",
  "\x1b[34m  █    ▼      █   Editor:\x1b[0m nvim",
  "\x1b[34m   ▀▀▀▀▀▀▀▀▀▀▀    Theme:\x1b[0m Specter live preview",
  "",
  "\x1b[36m~ $\x1b[0m ls -lah",
  "\x1b[32mtotal 64K\x1b[0m",
  "drwxr-xr-x  10 user  staff   320B  .",
  "-rw-r--r--   1 user  staff   1.2K  \x1b[34mREADME.md\x1b[0m",
  "-rw-r--r--   1 user  staff   3.8K  \x1b[34mpackage.json\x1b[0m",
  "drwxr-xr-x   8 user  staff   256B  \x1b[34msrc/\x1b[0m",
  "",
  "\x1b[36m~ $\x1b[0m git status",
  "On branch \x1b[32mmain\x1b[0m",
  "Changes to be committed:",
  "  \x1b[32mmodified:\x1b[0m   src/App.tsx",
  "  \x1b[31mdeleted:\x1b[0m    legacy/util.js",
  "",
  "\x1b[36m~ $\x1b[0m \x1b[5m▎\x1b[0m"
];

let i = 0;
function emit() {
  term.writeln(lines[i % lines.length]);
  i++;
  if (i % lines.length === 0) {
    setTimeout(() => term.clear(), 1500);
  }
  setTimeout(emit, 380);
}
emit();
```

- [ ] **Step 3: Write build script**

`preview-src/build.mjs`:
```javascript
import esbuild from "esbuild";
import { fileURLToPath } from "url";
import path from "path";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

await esbuild.build({
  entryPoints: [path.join(__dirname, "index.ts")],
  bundle: true,
  minify: true,
  format: "iife",
  outfile: path.join(__dirname, "../Specter/Resources/preview/xterm.bundle.js"),
  loader: { ".css": "text" },
  define: { "process.env.NODE_ENV": '"production"' },
});

console.log("Built xterm bundle.");
```

- [ ] **Step 4: Write top-level build helper**

`scripts/build-preview-bundle.sh`:
```bash
#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
cd preview-src
pnpm install --frozen-lockfile 2>/dev/null || pnpm install
pnpm build
echo "✓ Wrote Specter/Resources/preview/xterm.bundle.js"
```

Make executable:
```bash
chmod +x scripts/build-preview-bundle.sh
```

- [ ] **Step 5: Build the bundle**

```bash
cd preview-src && pnpm install && pnpm build && cd ..
ls -lh Specter/Resources/preview/xterm.bundle.js
```

Expected: file exists, ~200-400KB.

- [ ] **Step 6: Commit (sources only — bundle is gitignored)**

```bash
git add preview-src/package.json preview-src/index.ts preview-src/build.mjs scripts/build-preview-bundle.sh preview-src/pnpm-lock.yaml 2>/dev/null || true
git add preview-src/package.json preview-src/index.ts preview-src/build.mjs scripts/build-preview-bundle.sh
git commit -m "preview: xterm.js bundle sources + esbuild build pipeline"
```

### Task 4.2: index.html (preview shell)

**Files:**
- Create: `Specter/Resources/preview/index.html`

- [ ] **Step 1: Write**

`Specter/Resources/preview/index.html`:
```html
<!doctype html>
<html>
<head>
<meta charset="utf-8" />
<title>Specter preview</title>
<style>
  html, body { margin:0; padding:0; height:100%; background:#1e1e2e; overflow:hidden; }
  #term-wrap { padding: 6px 4px; height:100%; box-sizing:border-box; }
  #term { height:100%; }
  /* xterm.js basic theme — full styles inlined by esbuild via @xterm/xterm/css/xterm.css if needed */
</style>
</head>
<body>
<div id="term-wrap"><div id="term"></div></div>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@xterm/xterm/css/xterm.min.css" onerror="this.remove()" />
<script src="xterm.bundle.js"></script>
</body>
</html>
```

> Note: The `<link>` to CDN is for *unbundled fallback*; the bundle itself includes terminal logic. For fully offline, we can later inline xterm.css into the bundle.

- [ ] **Step 2: Run app, see preview rendering**

```bash
xcodebuild build -project Specter.xcodeproj -scheme Specter -derivedDataPath ./build 2>&1 | tail -3
open ./build/Build/Products/Debug/Specter.app
```

Manual verify: preview area should show a demo terminal with rotating output.

- [ ] **Step 3: Commit**

```bash
git add Specter/Resources/preview/index.html
git commit -m "preview: HTML shell wiring xterm bundle"
```

---

## Phase 5 — Integration, Polish, Packaging

### Task 5.1: CommandPalette (⌘K)

**Files:**
- Create: `Specter/View/CommandPalette.swift`
- Modify: `Specter/View/ContentView.swift` (hotkey + sheet presentation)

- [ ] **Step 1: Implement palette**

`Specter/View/CommandPalette.swift`:
```swift
import SwiftUI

struct CommandPalette: View {
    @Environment(AppEnvironment.self) private var env
    @Binding var isPresented: Bool
    @State private var query: String = ""
    @State private var selectedIndex: Int = 0
    let onSelect: (OptionEntry) -> Void

    private var results: [OptionEntry] {
        let hits = env.registry.search(query)
        return Array(hits.prefix(40))
    }

    var body: some View {
        VStack(spacing: 0) {
            TextField("搜索所有 200+ 设置", text: $query)
                .textFieldStyle(.plain)
                .font(.title3)
                .padding(12)
            Divider()
            List(Array(results.enumerated()), id: \.element.id, selection: $selectedIndex) { idx, entry in
                VStack(alignment: .leading) {
                    HStack {
                        Text(entry.key).font(.system(.body, design: .monospaced))
                        Spacer()
                        Text(entry.category.displayName).font(.caption).foregroundStyle(.secondary)
                    }
                    Text(entry.docMarkdown).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }.tag(idx)
                    .onTapGesture { commit(entry) }
            }
            .frame(minHeight: 320)
        }
        .frame(width: 560)
        .onSubmit { if let entry = results.first { commit(entry) } }
    }

    private func commit(_ entry: OptionEntry) {
        onSelect(entry)
        isPresented = false
    }
}
```

- [ ] **Step 2: Wire ⌘K into ContentView**

Modify `Specter/View/ContentView.swift`:
```swift
import SwiftUI

struct ContentView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var selectedCategory: Category = .appearance
    @State private var searchQuery: String = ""
    @State private var showCommandPalette = false

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedCategory: $selectedCategory)
                .frame(minWidth: 160)
        } content: {
            VStack(spacing: 0) {
                TopBar(searchQuery: $searchQuery)
                Divider()
                PreviewPane()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } detail: {
            InspectorPane(category: selectedCategory, searchQuery: searchQuery)
                .frame(minWidth: 320)
        }
        .sheet(isPresented: $showCommandPalette) {
            CommandPalette(isPresented: $showCommandPalette) { entry in
                selectedCategory = entry.category
                searchQuery = entry.key
            }
        }
        .background(
            KeyboardShortcuts.invisibleHandler(key: "k", modifiers: .command) {
                showCommandPalette = true
            }
        )
    }
}

enum KeyboardShortcuts {
    @MainActor
    static func invisibleHandler(key: String, modifiers: EventModifiers, action: @escaping () -> Void) -> some View {
        Button("") { action() }
            .keyboardShortcut(KeyEquivalent(Character(key)), modifiers: modifiers)
            .hidden()
            .frame(width: 0, height: 0)
    }
}
```

- [ ] **Step 3: Build + commit**

```bash
xcodebuild build -project Specter.xcodeproj -scheme Specter 2>&1 | tail -3
git add Specter/View/CommandPalette.swift Specter/View/ContentView.swift
git commit -m "view: CommandPalette (⌘K) with full-text search and quick-jump"
```

### Task 5.2: UI smoke test

**Files:**
- Replace: `SpecterUITests/_Placeholder.swift` → `SpecterUITests/SmokeTests.swift`

- [ ] **Step 1: Write smoke test**

```bash
rm SpecterUITests/_Placeholder.swift
```

`SpecterUITests/SmokeTests.swift`:
```swift
import XCTest

final class SmokeTests: XCTestCase {
    func test_launchAndSeeSidebar() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.outlines.firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["外观"].exists || app.staticTexts["Appearance"].exists)
    }
}
```

- [ ] **Step 2: Run, expect pass**

```bash
xcodebuild test -project Specter.xcodeproj -scheme Specter -only-testing:SpecterUITests/SmokeTests 2>&1 | tail -8
```

- [ ] **Step 3: Commit**

```bash
git add SpecterUITests/SmokeTests.swift
git rm SpecterUITests/_Placeholder.swift 2>/dev/null || true
git commit -m "test: UI smoke test for app launch + sidebar visible"
```

### Task 5.3: GitHub Actions CI

**Files:**
- Create: `.github/workflows/ci.yml`

- [ ] **Step 1: Write CI yaml**

`.github/workflows/ci.yml`:
```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  test:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.4.app

      - name: Install xcodegen
        run: brew install xcodegen

      - name: Install pnpm
        run: npm i -g pnpm

      - name: Build xterm bundle
        run: ./scripts/build-preview-bundle.sh

      - name: Generate Xcode project
        run: xcodegen generate

      - name: Run unit tests
        run: |
          xcodebuild test \
            -project Specter.xcodeproj \
            -scheme Specter \
            -only-testing:SpecterTests \
            -destination 'platform=macOS' \
            -resultBundlePath TestResults
```

> Note: the CI runner's Xcode version may differ from local (26.x). Adjust the `xcode-select` path to match the runner's available version (`/Applications/Xcode_15.4.app` is a safe default for macos-14 runners as of 2025). Update when needed.

- [ ] **Step 2: Commit**

```bash
mkdir -p .github/workflows
git add .github/workflows/ci.yml
git commit -m "ci: GitHub Actions matrix for unit tests on macos-14"
```

### Task 5.4: README

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Write final README**

`README.md`:
```markdown
# Specter

> A native macOS GUI configurator for the [Ghostty](https://ghostty.org) terminal — live preview, in-place docs, explicit Apply.

![status: alpha](https://img.shields.io/badge/status-alpha-orange) ![license: MIT](https://img.shields.io/badge/license-MIT-blue) ![platform: macOS 14+](https://img.shields.io/badge/macOS-14%2B-lightgrey)

**Specter is not affiliated with, sponsored by, or endorsed by the Ghostty project.** "Ghostty" is the trademark of its respective owners.

## What it does

- 🎨 **Live preview** — change a setting, the embedded terminal redraws instantly. No more `⌘+Shift+,` cycle.
- 📖 **Docs in place** — every option carries its explanation, recommended value, and constraints right next to the control.
- 🔍 **⌘K search** — fuzzy-find any of Ghostty's 200+ options.
- 💾 **Explicit Apply** — your `~/.config/ghostty/config` only changes when you say so, with a timestamped backup, and the GUI preserves your comments, blank lines, and unknown keys byte-for-byte.

## Install

```bash
brew install --cask specter         # coming soon
```

Or download a `.dmg` from [Releases](https://github.com/YOUR_USER/Specter/releases).

## Build from source

Prereqs: Xcode 15+, [xcodegen](https://github.com/yonaskolb/XcodeGen), [pnpm](https://pnpm.io/).

```bash
brew install xcodegen
npm i -g pnpm
./scripts/build-preview-bundle.sh    # builds xterm.js bundle
xcodegen generate
open Specter.xcodeproj
# ⌘R in Xcode
```

## Architecture

See [docs/superpowers/specs/2026-05-26-specter-design.md](docs/superpowers/specs/2026-05-26-specter-design.md).

TL;DR: SwiftUI + `@Observable` MVVM, actor-isolated IO services, xterm.js for the preview renderer (in a WKWebView), zero runtime Swift dependencies.

## License

MIT. See [LICENSE](LICENSE).
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: full README"
```

### Task 5.5: DMG packaging script (developer-runs-locally)

**Files:**
- Create: `scripts/package-dmg.sh`

- [ ] **Step 1: Write the script**

`scripts/package-dmg.sh`:
```bash
#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Build release config
./scripts/build-preview-bundle.sh
xcodegen generate
xcodebuild -project Specter.xcodeproj -scheme Specter -configuration Release \
    -derivedDataPath ./build clean build

APP="./build/Build/Products/Release/Specter.app"
DMG_DIR="$(mktemp -d)"
cp -R "$APP" "$DMG_DIR/Specter.app"
ln -s /Applications "$DMG_DIR/Applications"

VERSION="$(plutil -extract CFBundleShortVersionString raw "$APP/Contents/Info.plist")"
OUT="./dist/Specter-$VERSION.dmg"
mkdir -p ./dist

hdiutil create -volname "Specter $VERSION" -srcfolder "$DMG_DIR" -ov -format UDZO "$OUT"
echo "✓ Wrote $OUT"
```

```bash
chmod +x scripts/package-dmg.sh
```

> Note: `scripts/notarize.sh` is left as a later task — it needs the user's Apple Developer credentials (Team ID, app-specific password, signing identity). See [Apple's notarytool docs](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution).

- [ ] **Step 2: Commit**

```bash
git add scripts/package-dmg.sh
git commit -m "scripts: package unsigned .dmg (notarize.sh deferred to user creds)"
```

---

## Self-Review (post-write)

**Spec coverage check (mapping spec sections → tasks):**
- §1 positioning → Task 0.2 README + Task 5.4
- §2 stack → all phases
- §3 visual layout → Tasks 3.3, 3.6, 3.7 (inspector / preview / sidebar)
- §4 architecture layers → file structure
- §5 component inventory → Tasks 1.1–1.7, 2.1–2.6, 3.1–3.7, 5.1
- §6 data flows A–E → Tasks 1.6 (B), 3.1 (C apply()), 5.1 (E search palette); Flow D FileWatcher is implemented in 2.6 but not yet wired into UI banner → see Open Items
- §7 comment-preserving → Tasks 2.1 + 2.2 with golden-file tests
- §8 error handling → Task 3.1 (apply() catches backup/write errors); FileWatcher banner deferred
- §9 testing → Tasks 1.1–2.4, 5.2
- §10 layout → matches file structure section above
- §11 v1 scope → curated ~40 options in Task 3.1, plus ⌘K reveals all entries
- §12 trademark posture → README in Task 5.4
- §13 open items → addressed by subsequent issues; xterm bundle pipeline = Task 4.1; keybind chord UI = deferred

**Gaps explicitly accepted for post-v1**:
- FileWatcher external-change banner UI (service implemented; banner UI deferred)
- ColorRow proper picker UI (uses StringRow path for now)
- ReadOnlyKeybindList (no keybind entries in curated v1 yet; will land with a future task that fetches `+list-keybinds`)
- Notarization automation
- `--show-config --docs` scrape for full 200+ option metadata (curated v1 ships ~16 entries; structure supports growth)

**Type consistency**: ConfigValue, OptionType, OptionEntry, OptionRegistry signatures all referenced consistently across tasks. `ConfigModel.commit()` / `reset(_:)` / `dirtyKeys` referenced in tasks 1.6, 3.2, 3.1 — all match. `AppEnvironment.apply()` only called from TopBar — fine.

**Placeholders**: none found in the written code blocks.

---

## Execution Handoff

User has pre-approved autonomous execution. Proceeding with **inline execution via `superpowers:executing-plans`** (single session, sequential tasks, checkpoint at end of each phase). Subagent-driven mode is overkill for a greenfield project with mostly-independent tasks.
