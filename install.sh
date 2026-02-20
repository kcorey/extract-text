#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

# Build first
./build.sh

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
