import esbuild from "esbuild";
import { fileURLToPath } from "url";
import path from "path";
import fs from "fs/promises";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Plugin: inline imported CSS as a runtime `document.createElement("style")` injection,
// so the bundle is fully self-contained (no <link> to external CSS at runtime).
const inlineCssPlugin = {
  name: "inline-css",
  setup(build) {
    build.onLoad({ filter: /\.css$/ }, async (args) => {
      const css = await fs.readFile(args.path, "utf8");
      const js = `(() => {
        if (typeof document === "undefined") return;
        const s = document.createElement("style");
        s.textContent = ${JSON.stringify(css)};
        document.head.appendChild(s);
      })();`;
      return { contents: js, loader: "js" };
    });
  },
};

await esbuild.build({
  entryPoints: [path.join(__dirname, "index.ts")],
  bundle: true,
  minify: true,
  format: "iife",
  outfile: path.join(__dirname, "../Specter/Resources/preview/xterm.bundle.js"),
  plugins: [inlineCssPlugin],
  define: { "process.env.NODE_ENV": '"production"' },
});

console.log("✓ Wrote Specter/Resources/preview/xterm.bundle.js");
