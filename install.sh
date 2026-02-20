#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

# Build first
./build.sh

# Install binary to /usr/local/bin
echo ""
echo "Installing binary to /usr/local/bin..."
sudo cp extract-text /usr/local/bin/extract-text
sudo chmod 755 /usr/local/bin/extract-text
echo "Installed: /usr/local/bin/extract-text"

# Copy workflow to Services
DEST="$HOME/Library/Services/Extract Text.workflow"
echo ""
echo "Installing workflow..."
rm -rf "$DEST"
cp -R "Extract Text.workflow" "$DEST"

echo "Installed to: $DEST"
echo ""
echo "Flushing services cache..."
/System/Library/CoreServices/pbs -flush 2>/dev/null || true

echo ""
echo "Done! To use:"
echo "  1. Select files in Finder"
echo "  2. Right-click > Quick Actions > Extract Text"
echo ""
echo "If 'Extract Text' doesn't appear:"
echo "  - Open System Settings > Privacy & Security > Extensions > Finder Extensions"
echo "  - Ensure 'Extract Text' is enabled"
echo "  - Or log out and log back in"
