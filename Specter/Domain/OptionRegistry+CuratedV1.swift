import Foundation

extension OptionRegistry {
    static func curatedV1() -> OptionRegistry {
        let entries: [OptionEntry] = [
            // ── Appearance ────────────────────────────────────────────
            OptionEntry(
                key: "theme", type: .theme, defaultValue: .string(""),
                docMarkdown: "终端主题。可用 `light:Name,dark:Name` 跟随系统切换。",
                category: .appearance, isCurated: true),
            OptionEntry(
                key: "background-opacity", type: .double(range: 0...1),
                defaultValue: .double(1.0),
                docMarkdown: "窗口背景透明度。0 = 完全透明，1 = 不透明。",
                category: .appearance, isCurated: true),
            OptionEntry(
                key: "background-blur-radius", type: .integer(range: 0...50),
                defaultValue: .integer(0),
                docMarkdown: "背景毛玻璃模糊半径。仅当 background-opacity < 1 时生效。",
                category: .appearance, isCurated: true),

            // ── Font ─────────────────────────────────────────────────
            OptionEntry(
                key: "font-family", type: .font, defaultValue: .string("JetBrains Mono"),
                docMarkdown: "等宽字体名。建议安装 Nerd Font 版本以显示图标。",
                category: .font, isCurated: true),
            OptionEntry(
                key: "font-size", type: .integer(range: 8...72), defaultValue: .integer(14),
                docMarkdown: "字号 (pt)。常用 12–16。",
                category: .font, isCurated: true),
            OptionEntry(
                key: "font-feature", type: .string, defaultValue: .string(""),
                docMarkdown: "OpenType 字体特性（如 `+calt`, `-liga`）。",
                category: .font, isCurated: false),

            // ── Window ───────────────────────────────────────────────
            OptionEntry(
                key: "window-padding-x", type: .string, defaultValue: .string("4,2"),
                docMarkdown: "水平内边距 `left,right`（像素）。",
                category: .window, isCurated: true),
            OptionEntry(
                key: "window-padding-y", type: .string, defaultValue: .string("6,0"),
                docMarkdown: "垂直内边距 `top,bottom`（像素）。",
                category: .window, isCurated: true),
            OptionEntry(
                key: "confirm-close-surface",
                type: .enumeration(["false", "always", "true"]),
                defaultValue: .string("true"),
                docMarkdown: "关闭终端窗口/标签前是否二次确认。",
                category: .window, isCurated: true),

            // ── macOS ────────────────────────────────────────────────
            OptionEntry(
                key: "macos-titlebar-style",
                type: .enumeration(["transparent", "tabs", "native", "hidden"]),
                defaultValue: .string("transparent"),
                docMarkdown: "macOS 标题栏样式。`transparent` 与终端背景融为一体。",
                category: .macos, isCurated: true),
            OptionEntry(
                key: "macos-option-as-alt",
                type: .enumeration(["left", "right", "true", "false"]),
                defaultValue: .string("false"),
                docMarkdown: "Option 键当作 Alt 发送转义序列。`right` 只让右 Option 当 Alt，左 Option 保留为修饰键（用于块选）。",
                category: .macos, isCurated: true),

            // ── Cursor ───────────────────────────────────────────────
            OptionEntry(
                key: "cursor-style", type: .enumeration(["block", "bar", "underline"]),
                defaultValue: .string("block"),
                docMarkdown: "光标形状。",
                category: .cursor, isCurated: true),
            OptionEntry(
                key: "cursor-style-blink", type: .bool, defaultValue: .bool(true),
                docMarkdown: "光标是否闪烁。",
                category: .cursor, isCurated: true),

            // ── Mouse ────────────────────────────────────────────────
            OptionEntry(
                key: "selection-clear-on-typing", type: .bool, defaultValue: .bool(true),
                docMarkdown: "打字时是否清空当前选区。设为 false 可在选完后继续输入命令再粘贴。",
                category: .mouse, isCurated: true),
            OptionEntry(
                key: "mouse-hide-while-typing", type: .bool, defaultValue: .bool(false),
                docMarkdown: "打字时隐藏鼠标指针。",
                category: .mouse, isCurated: true),

            // ── Shell Integration ────────────────────────────────────
            OptionEntry(
                key: "shell-integration",
                type: .enumeration(["none", "detect", "bash", "elvish", "fish", "zsh"]),
                defaultValue: .string("detect"),
                docMarkdown: "Shell 集成方式（命令光标提示、标题更新、sudo 提示等）。",
                category: .shellIntegration, isCurated: true),
        ]
        let curated = Set(entries.filter { $0.isCurated }.map { $0.key })
        return OptionRegistry(entries: entries, curated: curated)
    }
}
