name: Build PSCoverDL

on:
  push:
    tags:
      - "v*"          # trigger on version tags, e.g. v1.2
  workflow_dispatch:  # allow manual runs from the Actions tab

jobs:
  build:
    strategy:
      fail-fast: false
      matrix:
        include:
          - os: windows-latest
            name: Windows
            artifact: pscoverdl-windows

          - os: macos-latest
            name: macOS
            artifact: pscoverdl-macos

          - os: ubuntu-latest
            name: Linux
            artifact: pscoverdl-linux

    runs-on: ${{ matrix.os }}
    name: Build on ${{ matrix.name }}

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      # -----------------------------------------------------------------------
      # Linux only: install Tkinter system dependency.
      # Tkinter is not bundled with the GitHub Actions Python on Ubuntu.
      # -----------------------------------------------------------------------
      - name: Install Tkinter (Linux only)
        if: matrix.os == 'ubuntu-latest'
        run: sudo apt-get update && sudo apt-get install -y python3-tk

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.11"

      - name: Install dependencies
        run: pip install -r requirements.txt pyinstaller certifi

      # -----------------------------------------------------------------------
      # macOS only: convert icon.png → icon.icns for proper Finder/Dock icon.
      # Uses macOS's built-in iconutil — no extra dependencies needed.
      # -----------------------------------------------------------------------
      - name: Generate .icns icon (macOS only)
        if: matrix.os == 'macos-latest'
        run: |
          mkdir -p src/app/icon.iconset
          python3 - <<'EOF'
          from PIL import Image
          import os
          src = "src/app/icon.png"
          sizes = [16, 32, 64, 128, 256, 512]
          for s in sizes:
              img = Image.open(src).resize((s, s), Image.LANCZOS)
              img.save(f"src/app/icon.iconset/icon_{s}x{s}.png")
              img2 = Image.open(src).resize((s*2, s*2), Image.LANCZOS)
              img2.save(f"src/app/icon.iconset/icon_{s}x{s}@2x.png")
          EOF
          iconutil -c icns src/app/icon.iconset -o src/app/icon.icns

      # -----------------------------------------------------------------------
      # Windows build
      # -----------------------------------------------------------------------
      - name: Build with PyInstaller (Windows)
        if: matrix.os == 'windows-latest'
        shell: pwsh
        run: |
          $CTK_PATH = python -c "import customtkinter, os; print(os.path.dirname(customtkinter.__file__))"
          pyinstaller `
            --noconfirm `
            --onedir `
            --windowed `
            --name pscoverdl `
            --add-data "$CTK_PATH;customtkinter" `
            --add-data "src/resources;resources" `
            --add-data "src/icons;icons" `
            --add-data "src/app;app" `
            src/gui.py

      # -----------------------------------------------------------------------
      # macOS build — uses .icns for dock/Finder icon, uploads only the .app
      # -----------------------------------------------------------------------
      - name: Build with PyInstaller (macOS)
        if: matrix.os == 'macos-latest'
        shell: bash
        run: |
          CTK_PATH=$(python3 -c "import customtkinter, os; print(os.path.dirname(customtkinter.__file__))")
          pyinstaller \
            --noconfirm \
            --onedir \
            --windowed \
            --name pscoverdl \
            --icon src/app/icon.icns \
            --osx-bundle-identifier com.pscoverdl.app \
            --add-data "$CTK_PATH:customtkinter" \
            --add-data "src/resources:resources" \
            --add-data "src/icons:icons" \
            --add-data "src/app:app" \
            src/gui.py

      - name: List dist output (macOS debug)
        if: matrix.os == 'macos-latest'
        shell: bash
        run: find dist/ -maxdepth 3 -print

      # PyInstaller should produce pscoverdl.app automatically with --windowed
      # on macOS. If it doesn't (headless CI quirk), wrap the onedir manually.
      - name: Ensure .app bundle exists (macOS)
        if: matrix.os == 'macos-latest'
        shell: bash
        run: |
          if [ ! -d "dist/pscoverdl.app" ]; then
            echo ".app not found — wrapping onedir into .app bundle manually"
            APP="dist/pscoverdl.app/Contents/MacOS"
            mkdir -p "$APP"
            cp -r dist/pscoverdl/* "$APP/"
            # Minimal Info.plist so macOS recognises it as an app
            cat > dist/pscoverdl.app/Contents/Info.plist <<'PLIST'
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
            "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
          <dict>
            <key>CFBundleName</key>
            <string>pscoverdl</string>
            <key>CFBundleExecutable</key>
            <string>pscoverdl</string>
            <key>CFBundleIdentifier</key>
            <string>com.pscoverdl.app</string>
            <key>CFBundleVersion</key>
            <string>1.0</string>
            <key>CFBundlePackageType</key>
            <string>APPL</string>
          </dict>
          </plist>
          PLIST
            echo ".app bundle created manually"
          else
            echo ".app bundle found at dist/pscoverdl.app"
          fi

      # -----------------------------------------------------------------------
      # Linux build
      # -----------------------------------------------------------------------
      - name: Build with PyInstaller (Linux)
        if: matrix.os == 'ubuntu-latest'
        shell: bash
        run: |
          CTK_PATH=$(python3 -c "import customtkinter, os; print(os.path.dirname(customtkinter.__file__))")
          pyinstaller \
            --noconfirm \
            --onedir \
            --windowed \
            --name pscoverdl \
            --add-data "$CTK_PATH:customtkinter" \
            --add-data "src/resources:resources" \
            --add-data "src/icons:icons" \
            --add-data "src/app:app" \
            src/gui.py

      # -----------------------------------------------------------------------
      # Upload artifacts.
      # macOS: only the .app bundle — users drag this to /Applications.
      # Windows/Linux: the full onedir folder.
      # -----------------------------------------------------------------------
      - name: Upload artifact (macOS — .app only)
        if: matrix.os == 'macos-latest'
        uses: actions/upload-artifact@v4
        with:
          name: ${{ matrix.artifact }}
          path: dist/pscoverdl.app
          if-no-files-found: error

      - name: Upload artifact (Windows / Linux)
        if: matrix.os != 'macos-latest'
        uses: actions/upload-artifact@v4
        with:
          name: ${{ matrix.artifact }}
          path: dist/pscoverdl/
          if-no-files-found: error

