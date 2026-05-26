#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
cd preview-src

if [ ! -d node_modules ]; then
  pnpm install --silent
  # pnpm 10+ requires explicit approval before native postinstall scripts run.
  # Try the modern syntax first; fall back silently if not supported.
  pnpm approve-builds esbuild 2>/dev/null || true
fi

pnpm build
echo "✓ xterm bundle ready at Specter/Resources/preview/xterm.bundle.js"
