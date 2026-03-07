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
# Run PyInstaller
#   --noconfirm          overwrite previous dist/ without prompting
#   --onedir             required by customtkinter (has bundled data files)
#   --windowed           no terminal window on launch (macOS: produces .app)
#   --name               output name
#   --add-data           bundle customtkinter data files (separator is : on Unix)
#   --add-data           bundle app resources (icons, game databases)
# ---------------------------------------------------------------------------
pyinstaller \
    --noconfirm \
    --onedir \
    --windowed \
    --name "pscoverdl" \
    --add-data "$CTK_PATH:customtkinter" \
    --add-data "$SRC_DIR/resources:resources" \
    --add-data "$SRC_DIR/icons:icons" \
    --add-data "$SRC_DIR/app:app" \
    "$SRC_DIR/gui.py"

echo ""
echo "[build] Done. Output is in: $SCRIPT_DIR/dist/pscoverdl/"

# On macOS PyInstaller also produces a .app bundle inside dist/
if [ "$PLATFORM" = "Darwin" ]; then
    echo "[build] macOS .app bundle: $SCRIPT_DIR/dist/pscoverdl.app"
fi
