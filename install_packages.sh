#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_FILE="$SCRIPT_DIR/packages.txt"
CHECK_ONLY=false

if [[ "${1:-}" == "--check" ]]; then
    CHECK_ONLY=true
fi

if [[ ! -f "$PACKAGES_FILE" ]]; then
    echo "Error: $PACKAGES_FILE not found"
    exit 1
fi

# Determine package manager
if command -v yay &>/dev/null; then
    PKG_MGR="yay"
    INSTALL_CMD=(yay -S --needed --noconfirm)
elif command -v pacman &>/dev/null; then
    PKG_MGR="pacman"
    INSTALL_CMD=(sudo pacman -S --needed --noconfirm)
else
    echo "Error: neither yay nor pacman found"
    exit 1
fi

echo "Using $PKG_MGR"

# Read packages (skip comments and blank lines)
mapfile -t packages < <(sed 's/#.*//; /^\s*$/d' "$PACKAGES_FILE")

installed=()
missing=()

for pkg in "${packages[@]}"; do
    if pacman -Qi "$pkg" &>/dev/null; then
        installed+=("$pkg")
    else
        missing+=("$pkg")
    fi
done

echo ""
echo "Already installed (${#installed[@]}):"
for pkg in "${installed[@]}"; do
    echo "  $pkg"
done

echo ""
echo "Missing (${#missing[@]}):"
for pkg in "${missing[@]}"; do
    echo "  $pkg"
done

if [[ ${#missing[@]} -eq 0 ]]; then
    echo ""
    echo "All packages are installed."
    exit 0
fi

if $CHECK_ONLY; then
    echo ""
    echo "Run without --check to install missing packages."
    exit 0
fi

echo ""
echo "Installing ${#missing[@]} package(s)..."
"${INSTALL_CMD[@]}" "${missing[@]}"

echo ""
echo "Done."
