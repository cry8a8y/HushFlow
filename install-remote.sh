#!/bin/bash
# Remote installer for HushFlow
# Usage: curl -fsSL https://raw.githubusercontent.com/cry8a8y/HushFlow/main/install-remote.sh | sh

set -e

REPO="https://github.com/cry8a8y/HushFlow.git"
INSTALL_DIR="${HUSHFLOW_HOME:-$HOME/.hushflow}"

echo ""
echo "  HushFlow"
echo "  Turn AI thinking time into mindful breathing."
echo ""

# Check git
if ! command -v git &>/dev/null; then
    echo "Error: git is required."
    exit 1
fi

# Clone or update
if [ -d "$INSTALL_DIR/.git" ]; then
    echo "Updating existing installation..."
    git -C "$INSTALL_DIR" pull --quiet
elif [ -d "$INSTALL_DIR" ]; then
    # Directory exists but isn't a git repo (e.g. only stats.log from a previous run)
    echo "Found existing $INSTALL_DIR (not a git repo). Reinstalling..."
    tmpdir=$(mktemp -d)
    git clone --quiet "$REPO" "$tmpdir"
    cp -a "$tmpdir"/. "$INSTALL_DIR"/
    rm -rf "$tmpdir"
else
    echo "Installing to $INSTALL_DIR..."
    git clone --quiet "$REPO" "$INSTALL_DIR"
fi

# Run installer
cd "$INSTALL_DIR"
bash install.sh "$@"

echo ""
echo "HushFlow installed at $INSTALL_DIR"
echo "To update later: cd $INSTALL_DIR && git pull"
