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

// Demo content (looped)
const lines: string[] = [
  "\x1b[36m~ $\x1b[0m neofetch",
  "\x1b[34m   ▄▀▀▀▀▀▀▀▀▀▄    \x1b[33mOS:\x1b[0m   macOS Sequoia",
  "\x1b[34m  █  ◯     ◯  █   \x1b[33mShell:\x1b[0m zsh 5.9",
  "\x1b[34m  █    ▼      █   \x1b[33mEditor:\x1b[0m nvim 0.10",
  "\x1b[34m   ▀▀▀▀▀▀▀▀▀▀▀    \x1b[33mTheme:\x1b[0m Specter live preview",
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
  "\x1b[36m~ $\x1b[0m \x1b[5m▎\x1b[0m",
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
