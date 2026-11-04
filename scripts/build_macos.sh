#!/usr/bin/env bash
# Build SmolChat.app (Apple Silicon) into dist/. Requires the project venv.
set -euo pipefail
cd "$(dirname "$0")/.."
PY=${PYTHON:-.venv/bin/python}

# App icon from the SVG logo (needs only macOS built-in tools + Qt).
if [ ! -f resources/assets/SmolChat.icns ]; then
  ICONSET=$(mktemp -d)/SmolChat.iconset
  mkdir -p "$ICONSET"
  for s in 16 32 64 128 256 512 1024; do
    "$PY" - "$s" "$ICONSET" <<'PY'
import sys
from PySide6.QtGui import QGuiApplication, QImage, QPainter
from PySide6.QtSvg import QSvgRenderer
from PySide6.QtCore import Qt
app = QGuiApplication([])
s, out = int(sys.argv[1]), sys.argv[2]
img = QImage(s, s, QImage.Format_ARGB32); img.fill(Qt.transparent)
p = QPainter(img); QSvgRenderer("resources/icons/logo.svg").render(p); p.end()
names = {16: ["icon_16x16"], 32: ["icon_16x16@2x", "icon_32x32"], 64: ["icon_32x32@2x"],
         128: ["icon_128x128"], 256: ["icon_128x128@2x", "icon_256x256"],
         512: ["icon_256x256@2x", "icon_512x512"], 1024: ["icon_512x512@2x"]}
for n in names[s]: img.save(f"{out}/{n}.png")
PY
  done
  iconutil -c icns "$ICONSET" -o resources/assets/SmolChat.icns
fi

"$PY" -m pip install --quiet "pyinstaller>=6.10"
"$PY" -m PyInstaller packaging/SmolChat.spec --noconfirm --distpath dist --workpath build
echo "Built dist/SmolChat.app"
echo "For distribution: codesign --deep --options runtime -s 'Developer ID Application: …' dist/SmolChat.app, then notarize with xcrun notarytool."
