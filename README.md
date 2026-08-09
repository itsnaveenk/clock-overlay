# Clock Overlay

A tiny native macOS clock that floats above every window — fullscreen apps included — and follows you across all your Spaces. Drag it anywhere; it remembers where you put it.

![Clock Overlay](assets/hero.png)

## Features

- Always on top — floats over fullscreen apps and on every Space
- Draggable — grab it and move it anywhere; the position is remembered
- Time, seconds, and date, in 12- or 24-hour format
- Transparent or boxed background, with adjustable size and opacity
- Automatic / light / dark themes
- Click-through mode so it never blocks your clicks
- Launch at login
- Menu bar companion with full settings
- No Dock icon, no window chrome — just the clock

## Install

Download the latest `ClockOverlay-*.dmg` from the [Releases page](../../releases), open it, and drag **Clock Overlay** into your **Applications** folder.

The app is ad-hoc signed (no paid Developer ID), so Gatekeeper asks to confirm the first launch: right-click the app → **Open** → **Open**.

## Usage

- **Drag** the clock with the mouse to move it.
- **Right-click** it for quick toggles: 12/24-hour, seconds, date, click-through, settings, quit.
- The **menu bar icon** opens the same options plus the Settings popover.

## Settings

Everything lives in the Settings popover (menu bar → **Settings…**).

| Setting | What it does |
|---|---|
| 12/24 hour | Time format |
| Seconds / Date | What appears beneath the time |
| Transparent background | Floating text vs. a rounded box |
| Size / Opacity | Scale and box opacity |
| Theme | Automatic, light, dark |
| Click-through | Let clicks pass to apps underneath |
| Launch at login | Start when you log in (needs the app in /Applications) |

## Building from source

No Xcode required — just Swift and Command Line Tools.

```sh
./build.sh        # builds and bundles ClockOverlay.app
./make-dmg.sh     # builds an installer DMG
```

Release builds are handled by [GitHub Actions](.github/workflows/release.yml): push a `v*` tag and the DMG is built and attached automatically.

## How it works

The clock lives in a borderless `NSPanel` at the status-bar window level, with `canJoinAllSpaces` and `fullScreenAuxiliary` collection behaviors — that combination keeps it above fullscreen apps and on every Space. Dragging uses AppKit's native `isMovableByWindowBackground`. Settings persist to `UserDefaults`; the login item uses `SMAppService`.

```
Sources/ClockOverlay/
  ClockOverlayApp.swift   # entry point
  AppDelegate.swift       # status bar menu, panel setup
  OverlayPanel.swift      # the floating window
  ClockView.swift         # the clock itself
  SettingsStore.swift     # persistence, themes, login item
  SettingsView.swift      # settings UI
```

## License

[MIT](LICENSE)
