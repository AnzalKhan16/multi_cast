#!/usr/bin/env bash
set -e

echo "=============================================="
echo "Building MultiCast Android Release Artifacts"
echo "=============================================="

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR/../multicast_app"

flutter clean
flutter pub get

echo "Building APK..."
flutter build apk --release --split-per-abi

echo "Building AppBundle..."
flutter build appbundle --release

echo "[SUCCESS] Android artifacts generated successfully in multicast_app/build/app/outputs/"
