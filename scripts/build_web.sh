#!/usr/bin/env bash
set -e

echo "=============================================="
echo "Building MultiCast Web Release Bundle"
echo "=============================================="

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR/../multicast_app"

flutter clean
flutter pub get

echo "Building Web Release with CanvasKit renderer..."
flutter build web --release --web-renderer canvaskit

echo "[SUCCESS] Web bundle generated successfully in multicast_app/build/web/"
