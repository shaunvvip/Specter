# Specter — Design Spec

> A native macOS GUI configurator for the Ghostty terminal.
> Status: design approved 2026-05-26.

## 1. Product Positioning

**One-liner**: A live-preview Inspector for Ghostty — change a setting, see the terminal redraw, click Apply.

**Differentiation (the "wow" moment)**:
- Primary: **A — live preview**. An embedded mini-terminal redraws as you tweak settings.
- Secondary: **B — docs-in-place**. Every option in the Inspector carries plain-language explanation + recommended value + visual example (replaces the round-trip to ghostty docs).
- Tertiary: **C — side-by-side comparison**. Compare 3–4 themes/fonts at once.
- Explicitly out of scope: **D — multi-profile dotfiles management** (deferred to v2+).

**Workflow model**: **Explicit Apply**. The GUI maintains an in-memory config; the user clicks Apply to write `~/.config/ghostty/config` (with automatic timestamped backup). This protects users with git-tracked dotfiles from surprise modifications. Mirrors VSCode Settings / Karabiner-Elements.

**Platform**: macOS-only (v1). Ghostty also supports Linux but v1 stays focused.

**Target user**:
- New Ghostty users overwhelmed by 200+ options and the lack of in-app help (B addresses this)
- Existing users tired of edit → ⌘+Shift+, → eyeball → repeat loop (A addresses this)
- Theme/font tinkerers (C addresses this)

## 2. Tech Stack

| Layer | Choice | Why |
|---|---|---|
| App framework | SwiftUI (macOS 14+) | Author writes Swift daily (FollowmeiOS line of work); modern, Apple-stable, zero learning cost |
| State | `@Observable` (Swift 5.9) | Fine-grained tracking, no Combine boilerplate |
| Concurrency | Swift 6 actors for IO services | Thread safety by construction |
| Preview rendering | xterm.js in WKWebView | Most-mature ANSI renderer; WKWebView is cheap on macOS; lets us match Ghostty colors/font/padding faithfully |
| Third-party Swift runtime deps | **None** | Zero shipped-binary deps is an OSS branding choice |
| Dev-time tools | SwiftLint (lint only, not bundled into app) | |
| JS deps | xterm.js (bundled at build time, no runtime fetch) | |
| Distribution | Homebrew Cask + GitHub Release (notarized DMG) | Mirrors Ghostty's own install workflow; author already has Apple Developer ID |
| License | MIT | |
| CI | GitHub Actions on `macos-14` runner | |

## 3. Visual Layout

**Inspector style** (Figma / Xcode inspired):

```
┌─────────────────────────────────────────────────────────────┐
│ TopBar │ Apply (3 unsaved) │ Reset │       ⌘K Search         │
├──────┬──────────────────────────────────────┬───────────────┤
│      │                                      │  外观         │
│ 外观 │       ┌────────────────────────┐    │  ─────────    │
│ 字体 │       │                        │    │  主题         │
│ 窗口 │       │   PREVIEW (xterm.js)   │    │  [TokyoNight] │
│ 键位 │       │                        │    │               │
│ 高级 │       │   ~ $ neofetch         │    │  字体         │
│      │       │   ...                  │    │  ─────────    │
│      │       │                        │    │  字号 [● 14]   │
│      │       └────────────────────────┘    │  ...          │
└──────┴──────────────────────────────────────┴───────────────┘
       ◄── 60px ──►  ◄────── center ──────►  ◄── 280px ──►
```

Rationale: Live preview is the core selling point, so it occupies the visual center.

## 4. Architecture Layers

```
View (SwiftUI)            — pure rendering, no business logic
Domain (Swift @Observable)— state + business rules; SwiftUI-free
Services (Swift actors)   — IO boundary: fs, CLI, AppleScript
Web Resources (bundled)   — xterm.js HTML/JS in app Resources/
```

Principles:
- Domain knows nothing of View — can be unit-tested in isolation.
- All IO is in actor-isolated services.
- `PreviewBridge` is a pure function `ConfigModel → XtermOptions` (snapshot-testable).
- View never directly invokes Services.

## 5. Component Inventory

### View (SwiftUI)

| Component | Responsibility |
|---|---|
| `SpecterApp` | App entry; injects environment objects |
| `ContentView` | 3-pane `NavigationSplitView` |
| `SidebarView` | Category navigation |
| `PreviewPane` | `WKWebView` wrapper + native↔JS bridge |
| `InspectorPane` | `Form` of OptionRows, grouped by category, with intra-category search |
| `OptionRow*` | One per control type: Toggle, Slider, ColorPicker, ThemePicker, FontPicker, EnumPicker, StringInput, ReadOnlyKeybindList |
| `TopBar` | Apply / Reset buttons, dirty badge, ⌘K search trigger |
| `CommandPalette` | ⌘K full-text search across all options |

### Domain (zero-SwiftUI Swift)

```swift
@Observable final class ConfigModel {
    var values: [String: ConfigValue]
    var dirtyKeys: Set<String> { get }
    func set(_ key: String, _ v: ConfigValue)
    func reset(_ key: String)
}

struct OptionRegistry {
    let entries: [OptionEntry]
    let curated: Set<String>           // ~30-50 keys shown by default in v1
    func search(_ q: String) -> [OptionEntry]
}

struct OptionEntry {
    let key: String                    // e.g. "font-size"
    let type: OptionType               // .integer, .string, .enum([...]), .color, .keybind, .font, .opacity, ...
    let defaultValue: ConfigValue
    let docMarkdown: String            // from `ghostty +show-config --default --docs`
    let category: Category
    let isCurated: Bool
}

enum PreviewBridge {
    static func translate(_ m: ConfigModel) -> XtermOptions
}

struct AppliedState {
    let snapshot: [String: ConfigValue]
}
```

### Services (Swift actors)

| Service | Public API | Notes |
|---|---|---|
| `GhostyCLI` | `listThemes() async throws / listFonts() / showConfigDocs() / version()` | Spawns `ghostty +X`; 3s timeout; caches results |
| `ConfigFileService` | `read() throws -> ParsedConfig` / `write(_ c: ConfigModel) throws` | Comment-preserving — see §7 |
| `BackupService` | `snapshot() throws -> URL` | Copies current config to `~/Library/Application Support/Specter/Backups/{ISO timestamp}.config`; auto-prunes to 20. (macOS-idiomatic location, won't pollute user's `.config` directory or git working tree.) |
| `ReloadHelper` | `requestReload() async` | AppleScript sends ⌘+Shift+, to frontmost Ghostty window; falls back to toast on failure |
| `FileWatcher` | publisher of `ExternalChange` events | `DispatchSource` on the config file; 250ms debounce |

### Web Resources

Bundled under `Specter.app/Contents/Resources/preview/`:
- `index.html` — xterm.js shell + JS bridge defining `window.applyPreview(opts)` and `window.loadDemo(content)`
- `xterm.bundle.js` — xterm.js compiled into a single file (no runtime CDN fetch)
- `demo.ans` — pre-recorded ANSI content (neofetch / ls / git diff styles) replayed on a loop

## 6. Data Flow

### Flow A — Startup

```
App.onAppear
  ├─ GhostyCLI.showConfigDocs() ──┐
  │  → OptionRegistry             │ parallel
  ├─ ConfigFileService.read() ────┘
  │  → ParsedConfig
  ├─ ConfigModel.init(from: parsed.values, registry)
  │  AppliedState.init(from: same)
  └─ View renders, initial preview applied
```
Startup budget: < 300ms.

### Flow B — Edit (in-memory only)

```
OptionRow user input
  → ConfigModel.set(key, value)
  → @Observable triggers PreviewPane observer
  → PreviewBridge.translate(model) → XtermOptions
  → WKWebView.evaluateJavaScript("applyPreview(...)")
  → xterm.js setOption → redraw
```
Latency budget: < 16ms (one frame).

### Flow C — Apply (writes to disk)

```
TopBar.applyButton.onTap
  ├─ BackupService.snapshot()         // backup BEFORE any write
  ├─ ConfigFileService.write(model)
  │    ├─ serialize tokens, patch only dirty keys
  │    ├─ write to tempfile → fsync → atomic rename
  │    └─ verify post-write
  ├─ AppliedState.commit(from: model) // dirtyKeys cleared
  └─ ReloadHelper.requestReload()     // best-effort; show fallback toast on failure
```

### Flow D — External change detection

```
FileWatcher (DispatchSource mtime/inode change)
  → if mtime ≠ last-read-mtime
  → banner: "File modified externally. [Reload & discard edits] [Keep editing]"
  → "Reload" runs Flow A again; "Keep editing" enters conflict mode (apply still allowed but with extra confirmation)
```

### Flow E — ⌘K search

```
TopBar.search.onSubmit(q)
  → OptionRegistry.search(q) → [OptionEntry]
  → CommandPalette shows results
  → user picks → ScrollViewReader scrollTo(key) → InspectorPane highlights row 1.5s
```

### Design Invariants

1. `ConfigModel` reflects only "currently-being-edited" state; is **never** written to disk by anything other than the Apply flow.
2. `AppliedState` is `ConfigModel`'s shadow snapshot — its only purpose is dirty diff.
3. PreviewPane has no independent state; every refresh is a re-run of `PreviewBridge`.
4. `ConfigFileService.write` is **byte-faithful** to all parts of the user's file we don't touch (comments, blanks, unknown keys).

## 7. Comment-Preserving Read/Write

`ConfigFileService.read()` returns a token stream, not a flat dict:

```swift
enum ConfigToken {
    case comment(String)        // "# ---- 字体 ----"
    case blank
    case entry(key: String, raw: String, recognized: Bool)
    case malformed(String)      // line we couldn't parse; kept verbatim
}

struct ParsedConfig {
    let tokens: [ConfigToken]
    let values: [String: ConfigValue]   // derived from .entry tokens
    let mtime: Date
}
```

`write(_ model:)` walks the token stream:
- `.entry(key, _, _)` where `dirtyKeys.contains(key)` → emit `"\(key) = \(newValue)"`
- everything else → emit verbatim
- newly-set keys (not in original) → appended to file footer under one autogenerated `# Added by Specter` heading (toggle via Specter Preferences, stored in `UserDefaults` under `com.specter.app`)

Guarantees:
1. User's comments, custom section dividers, and blank-line rhythm survive byte-for-byte.
2. Keys Specter doesn't know about (future Ghostty versions, user typos) are preserved.
3. `git diff ~/.config/ghostty/config` after Apply shows only the lines the user actually changed.

## 8. Error Handling

### Principles

- Startup-fatal errors → full-screen modal with explanation + action; never let the app run half-broken.
- Runtime-recoverable errors → toast/banner with retry; never silent.
- Data-safety errors → **fail-stop**: rather not write than write half.
- Invalid input → inline validation; Apply disabled while anything invalid.

### Specific failures

| Failure | Response |
|---|---|
| `ghostty` not on PATH | Startup modal: `brew install ghostty`; deep-link to website |
| `~/.config/ghostty/config` missing | Treat as empty config (defaults); create on first Apply |
| Config has syntax errors | Red top banner: "N unparseable lines [View]"; editor still usable for recognized keys; **Apply disabled** to prevent clobbering broken file |
| Disk full / permission denied during write | Toast with reason; preserve dirty state; offer retry |
| Backup fails | **Refuse to apply**; toast "Backup failed — refusing to apply" |
| Automation permission denied | First time: modal explaining permission flow + deep-link to System Settings → Privacy → Automation; subsequent: toast fallback (Apply still succeeds, just no auto-reload) |
| Ghostty not running | Toast: "Saved. Next launch will pick up changes" |
| CLI subprocess hang | 3s timeout + cancel; toast on cancel |
| Filewatcher event flood | 250ms debounce |
| Out-of-range input | OptionRow red border + tooltip; TopBar shows "⚠ 3 invalid" |
| External + Specter both changed | Flow D banner |
| Backup dir growth | Keep newest 20, auto-prune |
| Duplicate keys in original config | Take last; report in Issues pane |
| Unknown key in original config | Preserve verbatim; show under "Unknown / Advanced" section; read-only |
| WKWebView load failed | Preview pane shows "Preview unavailable [Retry]"; Inspector still works |
| xterm.js runtime error | JS `window.onerror` → native toast "Preview malfunctioned [Reload preview]" |

## 9. Testing Strategy

| Layer | What | How | Target |
|---|---|---|---|
| Domain | `PreviewBridge.translate`, `OptionRegistry.search`, `ConfigModel` mutators | XCTest pure-function tests | 90%+ |
| `ConfigFileService` parser/writer | byte-level preservation of comments, blanks, unknown keys | Golden-file tests under `Tests/Fixtures/`: input config → mutation → diff against expected output | 95%+ |
| `BackupService` | pre-write backup exists; 20-cap prune | XCTest + temp dir | 90% |
| `GhostyCLI` | timeout, output parsing | Inject fake binary via test shell script | 80% |
| UI smoke | startup → change font-size → Apply → file updated → preview redrew | One XCUITest happy-path | n/a |
| `PreviewBridge` snapshot | XtermOptions JSON stable across changes | Snapshot tests committed to repo; regression diff in CI | typical combos covered |

Not tested (manual checklist):
- xterm.js internal rendering
- AppleScript actually reloads Ghostty
- Notarization + Gatekeeper post-DMG

CI: GitHub Actions, `macos-14` runner, `swift test` + `xcodebuild test -scheme Specter` + `swiftlint --strict`. Release tag triggers `notarize-and-stamp` workflow.

## 10. Project Layout (v1)

> Current working directory is `~/personal-projects/ghostty-config-gui/` (placeholder name from before brand decision); will be renamed to `Specter/` before pushing to GitHub.


```
Specter/
├── Specter.xcodeproj/
├── Specter/                          # main app target
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
│   │       ├── ToggleRow.swift
│   │       ├── SliderRow.swift
│   │       ├── ColorRow.swift
│   │       ├── ThemeRow.swift
│   │       ├── FontRow.swift
│   │       ├── EnumRow.swift
│   │       ├── StringRow.swift
│   │       └── ReadOnlyKeybindList.swift
│   ├── Domain/
│   │   ├── ConfigModel.swift
│   │   ├── ConfigValue.swift
│   │   ├── OptionRegistry.swift
│   │   ├── OptionEntry.swift
│   │   ├── Category.swift
│   │   ├── AppliedState.swift
│   │   ├── PreviewBridge.swift
│   │   └── XtermOptions.swift
│   ├── Services/
│   │   ├── GhostyCLI.swift
│   │   ├── ConfigFileService.swift
│   │   ├── ConfigTokenizer.swift
│   │   ├── BackupService.swift
│   │   ├── ReloadHelper.swift
│   │   └── FileWatcher.swift
│   ├── Resources/
│   │   └── preview/
│   │       ├── index.html
│   │       ├── xterm.bundle.js
│   │       └── demo.ans
│   └── Assets.xcassets/
├── SpecterTests/                     # unit tests
│   ├── PreviewBridgeTests.swift
│   ├── ConfigFileServiceTests.swift
│   ├── BackupServiceTests.swift
│   ├── OptionRegistryTests.swift
│   ├── ConfigModelTests.swift
│   ├── GhostyCLITests.swift
│   └── Fixtures/
│       ├── basic.config
│       ├── basic-after-fontsize-change.config
│       ├── with-comments.config
│       └── ...
├── SpecterUITests/
│   └── SmokeTests.swift
├── scripts/
│   ├── build-xterm-bundle.sh         # one-shot: pnpm install + esbuild bundle
│   ├── notarize.sh                   # release script
│   └── package-dmg.sh
├── .github/workflows/
│   ├── ci.yml
│   └── release.yml
├── .gitignore
├── LICENSE                            # MIT
├── README.md
└── docs/
    └── superpowers/specs/
        └── 2026-05-26-specter-design.md
```

## 11. v1 Scope Cut

**In scope**:
- Inspector for ~40 curated options (theme, font-family, font-size, background-opacity, padding, cursor style, mouse selection, shell-integration, macos-titlebar-style, common keybinds search, etc.)
- Live preview with theme + font + opacity + padding accurate (no shader / ligature)
- Comment-preserving Apply with backup
- ⌘K search across all 200+ options (showing non-curated ones as "Advanced" rows)
- Read-only keybinds list with search
- AppleScript reload + fallback prompt
- Notarized DMG via GitHub Release
- Homebrew Cask formula

**Out of v1**:
- Multi-profile management (D)
- Side-by-side theme comparison (C) — deferred to v1.1
- Keybind editing (only read-only in v1)
- Linux support
- Mac App Store
- Custom shader preview
- Ligature / italic fine-tune preview accuracy

## 12. Trademark / Legal Posture

- Project name: **Specter** (independent name; no Ghostty trademark use)
- Subtitle in README: "*An unofficial GUI configurator for the Ghostty terminal*"
- Top of README disclaimer: "Specter is not affiliated with, sponsored by, or endorsed by the Ghostty project. 'Ghostty' is the trademark of its respective owners."
- License: MIT
- No bundling of Ghostty binary, themes, or logos. All Ghostty-side data fetched at runtime from user's local install.

## 13. Open Items (deferred to implementation plan)

- xterm.js bundle build pipeline (pnpm + esbuild script details)
- Specific keybind chord representation in the read-only viewer
- ColorRow's color picker UI fidelity (system NSColorWell vs custom)
- ThemePicker preview rendering strategy (full xterm.js redraw per hover vs pre-cached SVG thumbnails)
- Localization scope for v1 (English + Simplified Chinese? English-only?)

These are picked up in the implementation plan (writing-plans skill).
