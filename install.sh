#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config="${XDG_CONFIG_HOME:-$HOME/.config}"

links=(
  "nvim::$config/nvim"
  "ghostty::$config/ghostty"
  "tmux-sessionizer::$config/tmux-sessionizer"
  "3rd-party/tmux-sessionizer/tmux-sessionizer::$HOME/scripts/tmux-sessionizer"
  "home/tmux-sessionizer-hook::$HOME/.tmux-sessionizer"
)

if [ -f "$repo/.gitmodules" ] && [ ! -e "$repo/3rd-party/tmux-sessionizer/tmux-sessionizer" ]; then
  echo "init submodules"
  git -C "$repo" submodule update --init --depth 1
fi

for entry in "${links[@]}"; do
  src="$repo/${entry%%::*}"
  dst="${entry##*::}"
  name="${dst/#$HOME/~}"

  if [ ! -e "$src" ]; then
    echo "skip $name (not in repo)"
    continue
  fi

  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "ok   $name (already linked)"
    continue
  fi

  mkdir -p "$(dirname "$dst")"

  if [ -e "$dst" ] || [ -L "$dst" ]; then
    backup="$dst.backup.$(date +%Y%m%d%H%M%S)"
    mv "$dst" "$backup"
    echo "move $name -> $(basename "$backup")"
  fi

  ln -s "$src" "$dst"
  echo "link $name"
done

ts_conf="$repo/tmux-sessionizer/tmux-sessionizer.conf"
if [ ! -e "$ts_conf" ] && [ -e "$ts_conf.example" ]; then
  cp "$ts_conf.example" "$ts_conf"
  echo "seed ${ts_conf/#$HOME/~} (from example -- edit TS_SEARCH_PATHS)"
fi

case ":$PATH:" in
  *":$HOME/scripts:"*) ;;
  *) printf '\nnote: %s is not on PATH -- add to .zshrc:\n      export PATH="$HOME/scripts:$PATH"\n' "$HOME/scripts" ;;
esac
