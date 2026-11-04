#!/usr/bin/env bash
# Build SmolChat.app (Apple Silicon) into dist/. Requires the project venv.
set -euo pipefail
cd "$(dirname "$0")/.."
PY=${PYTHON:-.venv/bin/python}

# App icon (.icns) from the brand logo using macOS built-in tools.
LOGO=resources/assets/logo/logo-1254.png
if [ ! -f resources/assets/SmolChat.icns ] || [ "$LOGO" -nt resources/assets/SmolChat.icns ]; then
  ICONSET=$(mktemp -d)/SmolChat.iconset
  mkdir -p "$ICONSET"
  for s in 16 32 128 256 512; do
    sips -z $s $s "$LOGO" --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
    sips -z $((s * 2)) $((s * 2)) "$LOGO" --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
  done
  iconutil -c icns "$ICONSET" -o resources/assets/SmolChat.icns
fi

"$PY" -m pip install --quiet "pyinstaller>=6.10"
"$PY" -m PyInstaller packaging/SmolChat.spec --noconfirm --distpath dist --workpath build
echo "Built dist/SmolChat.app"
echo "For distribution: codesign --deep --options runtime -s 'Developer ID Application: …' dist/SmolChat.app, then notarize with xcrun notarytool."
