#!/usr/bin/env bash
set -uo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

skipped=()
failed=()

have() { command -v "$1" >/dev/null 2>&1; }
step() { printf '\n==> %s\n' "$1"; }
note() { printf '    %s\n' "$1"; }

try() {
  local what="$1"; shift
  if "$@"; then
    note "ok: $what"
  else
    note "FAILED: $what"
    failed+=("$what")
  fi
}

if [ "$(uname -s)" != "Darwin" ]; then
  echo "This bootstrap is macOS-only (Homebrew, Xcode, sourcekit-lsp)." >&2
  exit 1
fi

# Non-login shells may not have Homebrew on PATH yet. Add both macOS
# prefixes before probing for brew, nvim, tree-sitter, dotnet, etc.
export PATH="$HOME/.dotnet/tools:$PATH"
for brew_prefix in /opt/homebrew /usr/local; do
  if [ -x "$brew_prefix/bin/brew" ]; then
    export PATH="$brew_prefix/bin:$brew_prefix/sbin:$PATH"
    break
  fi
done

step "Homebrew packages"
if have brew; then
  try "brew bundle" brew bundle --file="$repo/Brewfile"
else
  note "brew not found -- install from https://brew.sh, then re-run"
  skipped+=("all Homebrew packages (brew missing)")
fi

step "Xcode toolchain"
if xcode-select -p >/dev/null 2>&1; then
  note "ok: developer dir at $(xcode-select -p)"
  if ! have sourcekit-lsp && ! [ -x "$(xcode-select -p)/usr/bin/sourcekit-lsp" ]; then
    note "sourcekit-lsp not found -- needs full Xcode, not just the CLT"
    skipped+=("sourcekit-lsp (install Xcode from the App Store)")
  fi
else
  note "no developer dir -- running xcode-select --install"
  xcode-select --install 2>/dev/null || true
  skipped+=("Xcode CLT (finish the GUI installer, then re-run)")
fi

step "rust-analyzer"
if have rustup; then
  try "rust-analyzer" rustup component add rust-analyzer
  try "clippy" rustup component add clippy
else
  skipped+=("rust-analyzer (no rustup -- see https://rustup.rs)")
fi

step "gopls"
if have go; then
  try "gopls" go install golang.org/x/tools/gopls@latest
  case ":$PATH:" in
    *":$(go env GOPATH)/bin:"*) ;;
    *) note "note: $(go env GOPATH)/bin is not on PATH" ;;
  esac
else
  skipped+=("gopls (no go toolchain)")
fi

step "python servers"
if have uv; then
  try "basedpyright" uv tool install --upgrade basedpyright
  try "ruff" uv tool install --upgrade ruff
else
  skipped+=("basedpyright, ruff (no uv)")
fi

step "roslyn-language-server"
if have dotnet; then
  if dotnet tool list --global 2>/dev/null | grep -q '^roslyn-language-server'; then
    try "roslyn-language-server (update)" dotnet tool update --global roslyn-language-server --prerelease
  else
    try "roslyn-language-server" dotnet tool install --global roslyn-language-server --prerelease
  fi
else
  skipped+=("roslyn-language-server (no dotnet)")
fi

step "tsgo"
if have npm; then
  try "@typescript/native-preview" npm install -g @typescript/native-preview
  if have tsc && ! tsc --lsp --help >/dev/null 2>&1; then
    note "note: global tsc is pre-7 and has no --lsp; tsgo works in projects"
    note "      that depend on @typescript/native-preview locally"
  fi
else
  skipped+=("tsgo (no npm)")
fi

step "neovim plugins"
if have nvim; then
  # treesitter.lua auto-installs parsers when the plugin loads, so the CLI must
  # exist before lazy installs/restores plugins. Otherwise headless nvim emits
  # ENOENT for every parser.
  if ! have tree-sitter && have brew; then
    try "tree-sitter CLI" brew install tree-sitter
  fi

  try "install plugins at locked versions" nvim --headless \
    "+lua require('lazy.manage').install({ wait = true, lockfile = true })" +qa

  try "restore drifted plugins" nvim --headless \
    "+lua require('lazy.manage').restore({ wait = true })" +qa

  if have tree-sitter; then
    try "treesitter parsers" nvim --headless \
      "+lua require('nvim-treesitter').install(require('cfg.parsers')):wait(600000)" +qa
  else
    skipped+=("treesitter parsers (tree-sitter CLI missing)")
  fi
else
  skipped+=("plugin sync (nvim not installed)")
fi

step "tmux-sessionizer"
for dep in tmux fzf; do
  have "$dep" || skipped+=("$dep (needed by tmux-sessionizer)")
done
if have tmux-sessionizer; then
  note "ok: on PATH at $(command -v tmux-sessionizer)"
else
  note "not on PATH -- run ./install.sh, and make sure .zshrc exports"
  note "\$HOME/scripts (this repo does not track .zshrc)"
  skipped+=("tmux-sessionizer on PATH")
fi

printf '\n'
if [ ${#failed[@]} -gt 0 ]; then
  echo "Failed:"
  printf '  - %s\n' "${failed[@]}"
fi
if [ ${#skipped[@]} -gt 0 ]; then
  echo "Skipped (needs manual work):"
  printf '  - %s\n' "${skipped[@]}"
fi
if [ ${#failed[@]} -eq 0 ] && [ ${#skipped[@]} -eq 0 ]; then
  echo "Everything installed."
fi

exit 0
