#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

echo "Compiling ExtractText.swift..."
swiftc -O -o extract-text ExtractText.swift

echo "Built: $(pwd)/extract-text"
echo "Size: $(du -h extract-text | cut -f1)"
