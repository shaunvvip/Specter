import { Terminal, ITheme } from "@xterm/xterm";
import "@xterm/xterm/css/xterm.css";

const termEl = document.getElementById("term") as HTMLElement;
const wrapEl = document.getElementById("term-wrap") as HTMLElement;

const term = new Terminal({
  fontFamily: "JetBrains Mono",
  fontSize: 14,
  cursorBlink: true,
  cursorStyle: "block",
  allowTransparency: true,
  theme: defaultTheme(),
  cols: 80,
  rows: 22,
});

term.open(termEl);

function defaultTheme(): ITheme {
  return {
    background: "#1e1e2e",
    foreground: "#cdd6f4",
    cursor: "#f5e0dc",
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
  term.options.fontFamily = opts.fontFamily || "JetBrains Mono";
  term.options.fontSize = opts.fontSize || 14;
  term.options.cursorBlink = opts.cursorBlink;
  term.options.cursorStyle = opts.cursorStyle;
  term.options.theme = opts.theme;
  document.body.style.background = applyOpacity(
    opts.theme.background ?? "#1e1e2e",
    opts.backgroundOpacity
  );
  if (wrapEl) {
    wrapEl.style.padding = `${opts.paddingY}px ${opts.paddingX}px`;
  }
};

function applyOpacity(hex: string, opacity: number): string {
  const h = hex.replace("#", "");
  const r = parseInt(h.slice(0, 2), 16);
  const g = parseInt(h.slice(2, 4), 16);
  const b = parseInt(h.slice(4, 6), 16);
  return `rgba(${r}, ${g}, ${b}, ${opacity})`;
}

// Static demo: written once, never looped or cleared.
// Reveals palette colors (0-15) + foreground + background so every theme change shows visible delta.
const lines: string[] = [
  "\x1b[36m~ $\x1b[0m neofetch",
  "",
  "                          \x1b[1m\x1b[34mOS\x1b[0m       macOS Sequoia",
  "       \x1b[33m///\x1b[36m////    \x1b[0m       \x1b[1m\x1b[34mHost\x1b[0m     MacBook Pro M3",
  "      \x1b[33m/////\x1b[36m///\x1b[31m/\x1b[0m       \x1b[1m\x1b[34mShell\x1b[0m    zsh 5.9",
  "     \x1b[33m//\x1b[31m///////\x1b[35m/\x1b[0m       \x1b[1m\x1b[34mEditor\x1b[0m   nvim 0.10",
  "    \x1b[31m/////////\x1b[35m///\x1b[0m       \x1b[1m\x1b[34mTerm\x1b[0m     Ghostty",
  "     \x1b[31m///\x1b[35m///////\x1b[34m/\x1b[0m       \x1b[1m\x1b[34mTheme\x1b[0m    Specter Preview",
  "      \x1b[35m/////\x1b[34m///\x1b[36m/\x1b[0m",
  "       \x1b[34m///\x1b[36m////\x1b[0m         \x1b[40m   \x1b[41m   \x1b[42m   \x1b[43m   \x1b[44m   \x1b[45m   \x1b[46m   \x1b[47m   \x1b[0m",
  "                          \x1b[100m   \x1b[101m   \x1b[102m   \x1b[103m   \x1b[104m   \x1b[105m   \x1b[106m   \x1b[107m   \x1b[0m",
  "",
  "\x1b[36m~ $\x1b[0m \x1b[32mgit status\x1b[0m",
  "On branch \x1b[32mmain\x1b[0m",
  "Changes to be committed:",
  "  \x1b[32mmodified:\x1b[0m   src/App.tsx",
  "  \x1b[31mdeleted:\x1b[0m    legacy/util.js",
  "  \x1b[33mrenamed:\x1b[0m    docs/old.md -> docs/v2.md",
  "",
  "\x1b[36m~ $\x1b[0m \x1b[34mls -lah\x1b[0m",
  "\x1b[2mdrwxr-xr-x  10 user  staff   320B  .\x1b[0m",
  "-rw-r--r--   1 user  staff   1.2K  \x1b[34mREADME.md\x1b[0m",
  "-rw-r--r--   1 user  staff   3.8K  \x1b[34mpackage.json\x1b[0m",
  "drwxr-xr-x   8 user  staff   256B  \x1b[34msrc/\x1b[0m",
  "",
  "\x1b[36m~ $\x1b[0m \x1b[7m▎\x1b[0m",
];

for (const line of lines) {
  term.writeln(line);
}
