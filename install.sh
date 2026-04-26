#!/bin/bash

set -e

DOC_NAME="kde-service-menu-reimage"

# Determine if KDE is installed
if command -v kbuildsycoca6 >/dev/null 2>&1; then
    kde_version=6
elif command -v kbuildsycoca5 >/dev/null 2>&1; then
    kde_version=5
else
    echo "Plasma KDE 5 or Plasma KDE 6 environment required! Exit..."
    exit 1
fi

# Determine if running as root
if [[ $EUID -eq 0 ]]; then
    echo "Installing system-wide KDE service menu..."

    bin_dir="/usr/local/bin"
    base_share_dir="/usr/share"
else
    echo "Installing KDE service menu locally for user..."

    bin_dir="$HOME/.local/bin"
    base_share_dir="$HOME/.local/share"
fi

desktop_dir="$base_share_dir/kio/servicemenus"
doc_dir="$base_share_dir/doc/$DOC_NAME"

# Create directories if they do not exist
install -vdm 755 "$bin_dir" "$desktop_dir" "$doc_dir"

# Copy binaries (if they exist)
if [ -d "./bin" ] && [ "$(ls -A ./bin)" ]; then
    echo "Copy binaries"
    install -vm 755 bin/* "$bin_dir/"
fi

# Copy service menus
echo "Copy service menus"
install -vm 755 servicemenus/* "$desktop_dir/"

# Copy documentation (maintaining structure)
echo "Copy documentation"
(cd doc && find . -type f -exec install -vDm 644 "{}" "$doc_dir/{}" \;)
install -vm 644 README.md "$doc_dir/README"

# Update KDE service cache
if [[ $kde_version -eq 6 ]]; then
    echo "Updating service cache (Plasma 6)"
    kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
elif [[ $kde_version -eq 5 ]]; then
    echo "Updating service cache (Plasma 5)"
    kbuildsycoca5 --noincremental >/dev/null 2>&1 || true
fi

echo "Installation completed!"

# Check if bin_dir is in PATH (only if binaries were installed and it's a user installation)
if [[ $EUID -ne 0 ]] && [ -d "./bin" ] && [ "$(ls -A ./bin)" ]; then
    if [[ ":$PATH:" != *":$bin_dir:"* ]]; then
        echo ""
        echo "⚠️  WARNING: $bin_dir is not in your PATH!"
        echo ""
        echo "To use the installed executable, add this line to your shell configuration:"
        echo ""
        echo "  export PATH=\"$bin_dir:\$PATH\""
        echo ""
        echo "For Bash (.bashrc):"
        echo "  echo 'export PATH=\"$bin_dir:\$PATH\"' >> ~/.bashrc"
        echo ""
        echo "For Zsh (.zshrc):"
        echo "  echo 'export PATH=\"$bin_dir:\$PATH\"' >> ~/.zshrc"
        echo ""
        echo "After adding it, restart your terminal or run 'source ~/.bashrc' (or ~/.zshrc)."
        echo ""
    fi
fi
