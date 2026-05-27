import { Terminal, ITheme } from "@xterm/xterm";
import "@xterm/xterm/css/xterm.css";

const termEl = document.getElementById("term") as HTMLElement;
const wrapEl = document.getElementById("term-wrap") as HTMLElement;

const term = new Terminal({
  // ui-monospace = macOS system monospaced (SF Mono); always available,
  // never falls back to a CJK font. Keep "JetBrains Mono" as the preferred
  // option for users who have installed it (the picker writes the chosen name
  // back here via applyPreview).
  fontFamily: '"JetBrains Mono", ui-monospace, "SF Mono", Menlo, Consolas, monospace',
  fontSize: 14,
  letterSpacing: 0,
  lineHeight: 1.2,
  cursorBlink: true,
  cursorStyle: "block",
  allowTransparency: true,
  drawBoldTextInBrightColors: true,
  theme: defaultTheme(),
  cols: 92,
  rows: 24,
  scrollback: 0,
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
  // The picker writes the chosen font as just "Family Name"; preserve our
  // ui-monospace fallback chain so an uninstalled name doesn't break rendering.
  const requested = opts.fontFamily?.trim() || "JetBrains Mono";
  term.options.fontFamily = `"${requested}", ui-monospace, "SF Mono", Menlo, Consolas, monospace`;
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

// ANSI helpers — keeps the demo source readable.
const reset = "\x1b[0m";
const dim   = "\x1b[2m";
const bold  = "\x1b[1m";
const fg = {
  red:    "\x1b[31m",
  green:  "\x1b[32m",
  yellow: "\x1b[33m",
  blue:   "\x1b[34m",
  magenta:"\x1b[35m",
  cyan:   "\x1b[36m",
  white:  "\x1b[37m",
  brightBlack: "\x1b[90m",
  brightGreen: "\x1b[92m",
};

// Static demo content — a realistic shell session a developer would recognize.
// Drawn once at init; no animation, no clear, no scroll.
const prompt = `${bold}${fg.green}specter${reset}${dim}:${reset}${fg.blue}~/code/Specter${reset}${dim} (${reset}${fg.magenta}main${dim})${reset} $ `;

const lines: string[] = [
  `${prompt}${fg.cyan}git${reset} status`,
  `On branch ${fg.green}main${reset}`,
  `Your branch is ${dim}up to date with${reset} '${fg.green}origin/main${reset}'.`,
  ``,
  `Changes not staged for commit:`,
  `  ${fg.red}modified:${reset}   Specter/View/PreviewPane.swift`,
  `  ${fg.red}modified:${reset}   Specter/View/Workspace/PreviewHalo.swift`,
  `  ${fg.red}modified:${reset}   preview-src/index.ts`,
  ``,
  `${prompt}${fg.cyan}git${reset} diff ${dim}preview-src/index.ts${reset}`,
  `${dim}@@ -8,7 +8,7 @@ const term = new Terminal({${reset}`,
  `${fg.red}-  fontFamily: "JetBrains Mono",${reset}`,
  `${fg.green}+  fontFamily: '"JetBrains Mono", ui-monospace, monospace',${reset}`,
  `${fg.green}+  letterSpacing: 0,${reset}`,
  ``,
  `${prompt}${fg.cyan}ls${reset} -lah`,
  `${dim}total 64K${reset}`,
  `drwxr-xr-x  ${fg.yellow}10${reset} shaun  staff  ${fg.brightGreen}320B${reset}  .`,
  `-rw-r--r--  ${fg.yellow} 1${reset} shaun  staff  ${fg.brightGreen}1.2K${reset}  ${fg.blue}README.md${reset}`,
  `-rw-r--r--  ${fg.yellow} 1${reset} shaun  staff  ${fg.brightGreen}3.8K${reset}  ${fg.blue}project.yml${reset}`,
  `drwxr-xr-x  ${fg.yellow} 8${reset} shaun  staff  ${fg.brightGreen}256B${reset}  ${fg.blue}Specter${reset}`,
  ``,
  `${prompt}`,
];

for (const line of lines) {
  term.writeln(line);
}
