import SwiftUI
import AppKit
import CoreGraphics
import Combine

extension Notification.Name {
    static let clockToggleClickThrough = Notification.Name("ClockOverlay.toggleClickThrough")
    static let clockOpenSettings = Notification.Name("ClockOverlay.openSettings")
    static let clockQuit = Notification.Name("ClockOverlay.quit")
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = SettingsStore()
    private let engine = Engine()
    private var panel: OverlayPanel!
    private var statusItem: NSStatusItem!
    private var settingsPopover: NSPopover?
    private var snapWorkItem: DispatchWorkItem?
    private var behaviorTimer: Timer?
    private var eventMonitor: Any?
    private var cancellables: Set<AnyCancellable> = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPanel()
        observeInternalNotifications()
        setupBehaviors()
    }

    func applicationWillTerminate(_ notification: Notification) {
        store.windowOrigin = panel?.frame.origin
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
    }

    // MARK: - Status bar menu

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "clock",
                                   accessibilityDescription: "Clock Overlay")
        }
        statusItem.menu = buildMenu()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let settings = NSMenuItem(title: "Settings…", action: #selector(showSettings), keyEquivalent: "")
        settings.target = self
        menu.addItem(settings)
        menu.addItem(.separator())

        let modeItem = NSMenuItem(title: "Mode", action: nil, keyEquivalent: "")
        let modeMenu = NSMenu()
        for mode in ClockMode.allCases {
            let item = NSMenuItem(title: mode.displayName, action: #selector(setMode(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = mode.rawValue
            item.state = store.mode == mode.rawValue ? .on : .off
            modeMenu.addItem(item)
        }
        modeItem.submenu = modeMenu
        menu.addItem(modeItem)
        menu.addItem(.separator())

        let h24 = NSMenuItem(title: "24-Hour Format", action: #selector(toggle24h), keyEquivalent: "")
        h24.target = self
        h24.state = store.use24h ? .on : .off
        menu.addItem(h24)

        let seconds = NSMenuItem(title: "Show Seconds", action: #selector(toggleSeconds), keyEquivalent: "")
        seconds.target = self
        seconds.state = store.showSeconds ? .on : .off
        menu.addItem(seconds)

        let date = NSMenuItem(title: "Show Date", action: #selector(toggleDate), keyEquivalent: "")
        date.target = self
        date.state = store.showDate ? .on : .off
        menu.addItem(date)

        menu.addItem(.separator())

        let clickThrough = NSMenuItem(title: "Click-Through Mode", action: #selector(toggleClickThrough), keyEquivalent: "")
        clickThrough.target = self
        clickThrough.state = store.clickThrough ? .on : .off
        menu.addItem(clickThrough)

        let login = NSMenuItem(title: "Launch at Login", action: #selector(toggleLogin), keyEquivalent: "")
        login.target = self
        login.state = store.launchesAtLogin ? .on : .off
        menu.addItem(login)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit Clock Overlay", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        return menu
    }

    // MARK: - Menu actions

    @objc private func setMode(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String else { return }
        store.mode = raw
        statusItem.menu = buildMenu()
    }

    @objc private func showSettings() {
        if settingsPopover == nil {
            let popover = NSPopover()
            popover.behavior = .transient
            let view = SettingsView(store: store, engine: engine, recorder: engine.recorder) { [weak self] enabled in
                self?.panel.applyClickThrough(enabled)
                self?.statusItem.menu = self?.buildMenu()
            }
            popover.contentViewController = NSHostingController(rootView: view)
            settingsPopover = popover
        }
        if let button = statusItem.button {
            settingsPopover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    @objc private func toggle24h() {
        store.use24h.toggle()
        statusItem.menu = buildMenu()
    }

    @objc private func toggleSeconds() {
        store.showSeconds.toggle()
        statusItem.menu = buildMenu()
    }

    @objc private func toggleDate() {
        store.showDate.toggle()
        statusItem.menu = buildMenu()
    }

    @objc private func toggleClickThrough() {
        store.clickThrough.toggle()
        panel.applyClickThrough(store.clickThrough)
        statusItem.menu = buildMenu()
    }

    @objc private func toggleLogin() {
        let enabled = !store.launchesAtLogin
        do {
            try store.setLaunchAtLogin(enabled)
        } catch {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "Couldn't update login item"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
        statusItem.menu = buildMenu()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    // MARK: - Overlay panel

    private func setupPanel() {
        panel = OverlayPanel()
        let hosting = NSHostingController(rootView: ClockView(store: store, engine: engine))
        panel.contentViewController = hosting
        panel.setContentSize(hosting.view.fittingSize)
        panel.setFrameOrigin(restoredOrigin(for: panel.frame.size))
        panel.applyClickThrough(store.clickThrough)

        NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.store.windowOrigin = self.panel.frame.origin
            self.scheduleSnap()
        }

        engine.onSessionComplete = { [weak self] _, _ in
            self?.flashPanel()
        }

        store.$mode
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self, let hosting = self.panel.contentViewController as? NSHostingController<ClockView> else { return }
                self.panel.setContentSize(hosting.view.fittingSize)
            }
            .store(in: &cancellables)

        panel.orderFrontRegardless()
    }

    private func restoredOrigin(for size: NSSize) -> CGPoint {
        if let saved = store.windowOrigin {
            let frame = NSRect(origin: saved, size: size)
            if NSScreen.screens.contains(where: { $0.visibleFrame.contains(frame) }) {
                return saved
            }
            // Saved position is off-screen (e.g. display disconnected); center on a screen.
            if let screen = NSScreen.screens.first(where: { $0.frame.intersects(frame) }) ?? NSScreen.main {
                return centeredOrigin(for: size, on: screen)
            }
        }
        guard let screen = NSScreen.main else { return .zero }
        let margin: CGFloat = 40
        return CGPoint(x: screen.visibleFrame.maxX - size.width - margin,
                       y: screen.visibleFrame.maxY - size.height - margin)
    }

    private func centeredOrigin(for size: NSSize, on screen: NSScreen) -> CGPoint {
        let visible = screen.visibleFrame
        return CGPoint(x: visible.midX - size.width / 2,
                       y: visible.midY - size.height / 2)
    }

    // MARK: - Internal notifications (posted by the clock context menu)

    private func observeInternalNotifications() {
        let center = NotificationCenter.default
        center.addObserver(forName: .clockToggleClickThrough, object: nil, queue: .main) { [weak self] _ in
            self?.toggleClickThrough()
        }
        center.addObserver(forName: .clockOpenSettings, object: nil, queue: .main) { [weak self] _ in
            self?.showSettings()
        }
        center.addObserver(forName: .clockQuit, object: nil, queue: .main) { _ in
            NSApp.terminate(nil)
        }
    }

    // MARK: - Behaviors

    private func setupBehaviors() {
        store.$doubleClickCyclesModes
            .receive(on: RunLoop.main)
            .sink { [weak self] enabled in
                self?.updateDoubleClickMonitor(enabled)
            }
            .store(in: &cancellables)

        let ticker = Timer(timeInterval: 2, repeats: true) { [weak self] _ in
            self?.tickBehaviors()
        }
        RunLoop.main.add(ticker, forMode: .common)
        behaviorTimer = ticker
    }

    private func updateDoubleClickMonitor(_ enabled: Bool) {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
        if enabled {
            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
                guard let self, event.window === self.panel, event.clickCount == 2 else { return event }
                self.cycleMode()
                return event
            }
        }
    }

    private func tickBehaviors() {
        updateFullscreenHide()
        updateIdleFade()
    }

    private func cycleMode() {
        let all = ClockMode.allCases
        guard let index = all.firstIndex(of: store.currentMode) else { return }
        store.mode = all[(index + 1) % all.count].rawValue
    }

    private func flashPanel() {
        NSSound.beep()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            panel.animator().alphaValue = 0.35
        } completionHandler: {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.25
                self.panel.animator().alphaValue = 1
            }
        }
    }

    // MARK: Auto-hide in fullscreen

    private func updateFullscreenHide() {
        guard store.autoHideInFullscreen else {
            if !panel.isVisible {
                panel.orderFrontRegardless()
            }
            return
        }
        let fullscreen = isFullscreenAppActive()
        if fullscreen, panel.isVisible {
            panel.orderOut(nil)
        } else if !fullscreen, !panel.isVisible {
            panel.orderFrontRegardless()
        }
    }

    private func isFullscreenAppActive() -> Bool {
        guard let activeApp = NSWorkspace.shared.frontmostApplication else { return false }
        let ourPID = NSRunningApplication.current.processIdentifier
        guard activeApp.processIdentifier != ourPID else { return false }

        guard let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] else {
            return false
        }
        let activePID = activeApp.processIdentifier
        for window in windows {
            guard let pid = window[kCGWindowOwnerPID as String] as? Int, pid == activePID else { continue }
            guard let layer = window[kCGWindowLayer as String] as? Int, layer == 0 else { continue }
            guard let dict = window[kCGWindowBounds as String] as? [String: CGFloat],
                  let x = dict["X"], let y = dict["Y"],
                  let w = dict["Width"], let h = dict["Height"] else { continue }
            let frame = CGRect(x: x, y: y, width: w, height: h)
            if NSScreen.screens.contains(where: { $0.frame.equalTo(frame) }) {
                return true
            }
        }
        return false
    }

    // MARK: Idle fade

    private func updateIdleFade() {
        guard store.idleFade else {
            if panel.alphaValue != 1 {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.3
                    panel.animator().alphaValue = 1
                }
            }
            return
        }
        guard let anyInput = CGEventType(rawValue: ~0) else { return }
        let idle = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyInput)
        let threshold: CFTimeInterval = 90
        if idle > threshold {
            if panel.alphaValue > 0.25 {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 1.0
                    panel.animator().alphaValue = 0.25
                }
            }
        } else if panel.alphaValue < 1 {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                panel.animator().alphaValue = 1
            }
        }
    }

    // MARK: Edge snapping

    private func scheduleSnap() {
        guard store.edgeSnapping else { return }
        snapWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.snapIfNeeded()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
        snapWorkItem = work
    }

    private func snapIfNeeded() {
        guard store.edgeSnapping, let screen = screenContaining(panel.frame) else { return }
        let visible = screen.visibleFrame
        let frame = panel.frame
        let threshold: CGFloat = 28
        var x = frame.origin.x
        var y = frame.origin.y
        var changed = false

        if frame.minX <= visible.minX + threshold {
            x = visible.minX
            changed = true
        } else if frame.maxX >= visible.maxX - threshold {
            x = visible.maxX - frame.width
            changed = true
        }
        if frame.minY <= visible.minY + threshold {
            y = visible.minY
            changed = true
        } else if frame.maxY >= visible.maxY - threshold {
            y = visible.maxY - frame.height
            changed = true
        }

        if changed {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.15
                panel.animator().setFrameOrigin(CGPoint(x: x, y: y))
            }
        }
    }

    private func screenContaining(_ frame: NSRect) -> NSScreen? {
        NSScreen.screens.first { $0.frame.intersects(frame) }
    }
}
