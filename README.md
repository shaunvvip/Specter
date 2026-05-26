# Specter

> A native macOS GUI configurator for the [Ghostty](https://ghostty.org) terminal — live preview, in-place docs, explicit Apply.

![status: alpha](https://img.shields.io/badge/status-alpha-orange) ![license: MIT](https://img.shields.io/badge/license-MIT-blue) ![platform: macOS 14+](https://img.shields.io/badge/macOS-14%2B-lightgrey)

**Specter is not affiliated with, sponsored by, or endorsed by the Ghostty project.** "Ghostty" is the trademark of its respective owners.

## What it does

- 🎨 **Live preview** — change a setting, the embedded terminal redraws instantly. No more `⌘+Shift+,` cycle.
- 📖 **Docs in place** — every option carries its explanation, recommended value, and constraints right next to the control.
- 🔍 **⌘K command palette** — fuzzy-find any of Ghostty's options.
- 💾 **Explicit Apply** — your `~/.config/ghostty/config` only changes when you say so, with a timestamped backup, and the GUI preserves your comments, blank lines, and unknown keys byte-for-byte.

## Install

```bash
brew install --cask specter         # coming soon
```

Or download a `.dmg` from [Releases](https://github.com/YOUR_USER/Specter/releases) (once signed/notarized releases are out).

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

**TL;DR:** SwiftUI + `@Observable` MVVM + actor-isolated IO services + xterm.js for the preview renderer (in a WKWebView). Zero runtime Swift dependencies.

```
View (SwiftUI)            — pure rendering
Domain (@Observable)      — ConfigModel, OptionRegistry, PreviewBridge
Services (actors)         — ConfigFileService, BackupService, GhostyCLI, ReloadHelper, FileWatcher
Web Resources (bundled)   — xterm.js bundle + HTML shell
```

## v1 scope

- 16 curated options across appearance / font / window / cursor / mouse / macOS / shell-integration
- Live preview tracks: theme (Mocha + TokyoNight builtin), font family, font size, background opacity, padding, cursor style, cursor blink
- ⌘K search reaches every option (curated and non-curated)
- Explicit Apply with automatic timestamped backup to `~/Library/Application Support/Specter/Backups/`
- AppleScript-driven Ghostty reload (with toast fallback)

Out of v1: multi-profile management, side-by-side theme comparison, keybind editing (read-only viewer planned), Linux, App Store, custom shader preview.

## Develop

```bash
./scripts/build-preview-bundle.sh    # one-shot when preview-src/ changes
xcodegen generate                    # when project.yml changes or new Swift files added
xcodebuild test -project Specter.xcodeproj -scheme Specter -only-testing:SpecterTests -destination 'platform=macOS'
```

## License

MIT. See [LICENSE](LICENSE).
