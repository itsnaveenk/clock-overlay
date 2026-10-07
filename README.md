# Clock Overlay

<p align="center">
  <img src="assets/hero.png" alt="Clock Overlay screenshot" width="900" />
</p>

<p align="center">
  A beautiful floating clock + focus timer for macOS that stays visible across Spaces and fullscreen apps.
</p>

<p align="center">
  <a href="../../releases"><img alt="GitHub release" src="https://img.shields.io/github/v/release/itsnaveenk/clock-overlay"></a>
  <a href="LICENSE"><img alt="MIT License" src="https://img.shields.io/badge/license-MIT-blue.svg"></a>
  <img alt="Platform" src="https://img.shields.io/badge/platform-macOS%2014%2B-black">
  <img alt="Built with Swift" src="https://img.shields.io/badge/Built%20with-Swift-orange">
</p>

Clock Overlay is a lightweight native macOS overlay for people who want time and focus tools always in view without switching windows.

It runs as a menu bar utility (no Dock icon), floats above other windows, supports multiple timer modes, and remembers your setup.

---

## Why Clock Overlay?

- **Always visible** while coding, presenting, studying, streaming, or recording
- **Zero clutter**: no big app window, just the clock/timer overlay
- **Productivity-first modes**: digital, analog, stopwatch, countdown, pomodoro, and laser focus
- **Highly customizable**: themes, fonts, size, opacity, and background styles
- **Native + private**: built with Swift/AppKit/SwiftUI, no cloud dependency

## Features

### Overlay behavior
- Floats above regular and fullscreen apps (`NSPanel` at status-bar level)
- Appears across all Spaces
- Drag to place anywhere (position persists)
- Optional click-through mode so it never blocks interactions
- Optional edge snapping
- Optional auto-hide in fullscreen apps
- Optional idle fade

### Clock + timer modes
- **Digital clock**
- **Analog clock**
- **Stopwatch**
- **Countdown timer**
- **Pomodoro timer** (work/break cycles)
- **Laser Focus timer**

### Personalization
- Light/dark-inspired built-in themes + custom colors
- Transparent / solid / frosted backgrounds
- Custom font picker
- Adjustable size and opacity
- 12/24-hour format and date display

### Companion controls
- Menu bar app with quick controls
- Right-click context menu directly on the overlay
- Launch at login support
- Session history for completed countdown/focus/pomodoro runs

## Installation

### Option 1: Download release (recommended)

1. Open the [Releases page](../../releases)
2. Download the latest `ClockOverlay-*.dmg`
3. Open the DMG and drag **Clock Overlay** to **Applications**

### First launch note (Gatekeeper)

The app is ad-hoc signed (no paid Apple Developer ID), so macOS may block the first launch.

To open:
1. Right-click **Clock Overlay.app**
2. Click **Open**
3. Confirm **Open** again

## Quick start

- **Move overlay**: drag it with your mouse
- **Open controls**: click the menu bar clock icon
- **Quick actions on overlay**: right-click for mode/timer/settings actions
- **Configure everything**: Menu bar → **Settings…**

## Building from source

### Requirements
- macOS 14+
- Swift 5.10+
- Xcode Command Line Tools

### Build app bundle

```sh
./build.sh
```

Output: `build/ClockOverlay.app`

### Build distributable DMG

```sh
./make-dmg.sh
```

Output: `dist/ClockOverlay-<version>.dmg`

## Release workflow

A GitHub Actions workflow builds and attaches the DMG when you push a tag like `v1.2.0`.

Workflow file: `.github/workflows/release.yml`

## Project structure

```text
Sources/ClockOverlay/
  ClockOverlayApp.swift   # entry point
  AppDelegate.swift       # menu bar controls, panel lifecycle
  OverlayPanel.swift      # floating NSPanel behavior
  ClockView.swift         # rendering + context menu
  Engine.swift            # stopwatch/countdown/pomodoro/focus logic
  SettingsStore.swift     # persisted settings + launch at login
  SettingsView.swift      # settings UI
  SessionRecorder.swift   # local session history
```

## Privacy

Clock Overlay runs locally on your Mac.
It stores preferences and session history on-device and does not require an account.

## Contributing

Contributions are welcome.

- Open an issue for bugs or feature ideas
- Submit a PR with a clear summary and screenshots (if UI-related)
- Keep changes scoped and focused

## Roadmap ideas

- Optional global shortcuts
- More overlay layouts/themes
- Exportable focus session analytics
- Multi-language UI support

## License

[MIT](LICENSE)
