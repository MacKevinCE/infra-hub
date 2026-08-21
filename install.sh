#!/bin/bash
set -e
cd "$(dirname "$0")"
swift build -c release
codesign --sign - .build/release/hub
cp .build/release/hub /usr/local/bin/hub
echo "hub $(./build/release/hub --version 2>/dev/null || echo 'installed') → /usr/local/bin/hub"
