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
    echo "unknown subcommand" >&2
    exit 2
    ;;
esac
