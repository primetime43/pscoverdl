#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# build.sh — PSCoverDL build script for macOS and Linux
#
# Produces a self-contained app in dist/pscoverdl/
#
# Usage:
#   chmod +x build.sh
#   ./build.sh
# ---------------------------------------------------------------------------

set -euo pipefail

# Resolve the directory this script lives in (repo root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src"

echo "[build] Detecting platform..."
PLATFORM="$(uname -s)"
case "$PLATFORM" in
    Darwin) echo "[build] macOS detected" ;;
    Linux)  echo "[build] Linux detected" ;;
    *)      echo "[build] Unsupported platform: $PLATFORM"; exit 1 ;;
esac

# ---------------------------------------------------------------------------
# Locate the customtkinter package directory so PyInstaller can bundle it.
# PyInstaller does not auto-include customtkinter's data files (.json, .otf).
# ---------------------------------------------------------------------------
CTK_PATH="$(python3 -c "import customtkinter; import os; print(os.path.dirname(customtkinter.__file__))")"
echo "[build] customtkinter found at: $CTK_PATH"

# ---------------------------------------------------------------------------
# macOS only: generate .icns icon from icon.png for proper Finder/Dock icon
# ---------------------------------------------------------------------------
if [ "$PLATFORM" = "Darwin" ]; then
    echo "[build] Generating .icns icon..."
    mkdir -p "$SRC_DIR/app/icon.iconset"
    python3 - <<EOF
from PIL import Image
src = "$SRC_DIR/app/icon.png"
sizes = [16, 32, 64, 128, 256, 512]
for s in sizes:
    img = Image.open(src).resize((s, s), Image.LANCZOS)
    img.save(f"$SRC_DIR/app/icon.iconset/icon_{s}x{s}.png")
    img2 = Image.open(src).resize((s*2, s*2), Image.LANCZOS)
    img2.save(f"$SRC_DIR/app/icon.iconset/icon_{s}x{s}@2x.png")
EOF
    iconutil -c icns "$SRC_DIR/app/icon.iconset" -o "$SRC_DIR/app/icon.icns"
    echo "[build] .icns generated at $SRC_DIR/app/icon.icns"
    ICON_ARG="--icon=$SRC_DIR/app/icon.icns"
    BUNDLE_ARG="--osx-bundle-identifier=com.pscoverdl.app"
else
    ICON_ARG=""
    BUNDLE_ARG=""
fi

# ---------------------------------------------------------------------------
# Run PyInstaller via python3 -m to avoid PATH issues
# ---------------------------------------------------------------------------
python3 -m PyInstaller \
    --noconfirm \
    --onedir \
    --windowed \
    "--name=pscoverdl" \
    ${ICON_ARG:+"$ICON_ARG"} \
    ${BUNDLE_ARG:+"$BUNDLE_ARG"} \
    "--add-data=$CTK_PATH:customtkinter" \
    "--add-data=$SRC_DIR/resources:resources" \
    "--add-data=$SRC_DIR/icons:icons" \
    "--add-data=$SRC_DIR/app:app" \
    "$SRC_DIR/gui.py"

echo ""
echo "[build] Done. Output is in: $SCRIPT_DIR/dist/pscoverdl/"

if [ "$PLATFORM" = "Darwin" ]; then
    echo "[build] macOS .app bundle: $SCRIPT_DIR/dist/pscoverdl.app"
fi

