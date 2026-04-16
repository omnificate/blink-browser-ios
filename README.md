# Blink Browser for iOS

A bleeding-edge, native iOS web browser built with Swift and optionally powered by the **Chromium Blink engine**. This project provides:

1. **Native iOS Browser App** (Swift/UIKit) — A fully-featured browser with tabbed browsing, bookmarks, history, ad blocking, reader mode, incognito mode, and more
2. **Chromium Blink Engine Integration** — Scripts and CI/CD to build Chromium with Blink for iOS (requires iOS 17.4+ via BrowserEngineKit)
3. **GitHub Actions CI/CD** — Automated builds producing IPA and TIPA (TrollStore IPA) artifacts
4. **TrollStore Compatibility** — Unsigned IPA for sideloading via TrollStore on iOS 14.0–17.0

## Features

- **Multi-tab browsing** with visual tab switcher
- **Smart URL/search bar** with auto-detection
- **Bookmarks** with add/remove/organize
- **Browsing history** with search
- **Ad & tracker blocking** (200+ domains)
- **Reader mode** for distraction-free reading
- **Incognito/private browsing** — no history, no cookies
- **Find in page** with highlight
- **Dark/Light mode** support
- **Desktop mode** toggle
- **Pull to refresh**
- **Progress indicator**
- **Swipe back/forward** gesture navigation

## Architecture

### Default Build (WebKit)
The default build uses WKWebView (WebKit), which works on **all iOS versions** from iOS 14+. This is the recommended build for most users.

### Blink Engine Build (Experimental)
For iOS 17.4+ or TrollStore devices, the browser can use Chromium's **Blink rendering engine** via Apple's BrowserEngineKit. This requires:
- macOS with Xcode 15.3+
- ~100GB disk space for Chromium source
- ~2-4 hours build time

## Building

### Quick Build (WebKit, GitHub Actions)
1. Fork this repository
2. Go to Actions → "Build iOS IPA"
3. Click "Run workflow"
4. Download the IPA/TIPA from the artifacts

### Local Build
```bash
# Install xcodegen
brew install xcodegen

# Generate Xcode project
xcodegen generate

# Build
xcodebuild -project BlinkBrowser.xcodeproj \
  -scheme BlinkBrowser \
  -destination 'generic/platform=iOS' \
  -archivePath build/BlinkBrowser.xcarchive \
  archive

# Package IPA
./Scripts/package_ipa.sh
```

### Chromium Blink Build
```bash
# Fetch Chromium source (warning: ~30GB download)
./Scripts/fetch_chromium.sh

# Build Chromium for iOS with Blink
./Scripts/build_chromium.sh

# The resulting framework will be at:
# chromium/src/out/Release-iphoneos/Chromium.framework
```

## TrollStore Installation

1. Build or download the TIPA file from GitHub Actions artifacts
2. Open TrollStore on your device
3. Install the TIPA file
4. The browser will appear on your home screen

### TrollStore Compatibility
| iOS Version | Device | Method |
|---|---|---|
| 14.0 β2 – 14.8.1 | All | TrollInstallerX |
| 15.0 – 15.5 β4 | All | TrollHelperOTA |
| 15.5 – 16.6.1 | All | TrollInstallerX/TrollHelperOTA |
| 16.7 RC | All | TrollHelper |
| 17.0 β1 – 17.0 | A12+ | TrollRestore |

## Project Structure

```
├── BlinkBrowser/
│   ├── AppDelegate.swift          # App lifecycle
│   ├── SceneDelegate.swift        # Scene management
│   ├── BrowserViewController.swift # Main browser UI
│   ├── TabManager.swift           # Tab management
│   ├── WebViewTab.swift           # Individual tab
│   ├── URLBarView.swift           # Address bar
│   ├── TabSwitcherView.swift      # Tab grid
│   ├── MenuViewController.swift   # Browser menu
│   ├── BookmarkManager.swift      # Bookmarks storage
│   ├── HistoryManager.swift       # History storage
│   ├── AdBlocker.swift            # Ad/tracker blocking
│   ├── ReaderMode.swift           # Reader view
│   └── Info.plist                 # App configuration
├── Scripts/
│   ├── fetch_chromium.sh          # Download Chromium source
│   ├── build_chromium.sh          # Build Blink for iOS
│   ├── package_ipa.sh            # Create IPA from build
│   └── create_tipa.sh           # Convert IPA to TIPA
├── .github/workflows/
│   ├── build-ipa.yml             # Build WebKit IPA
│   └── build-blink.yml          # Build Blink engine
├── project.yml                   # xcodegen specification
└── README.md
```

## License

MIT License — See LICENSE for details.
