import SwiftUI
import AppKit

extension Notification.Name {
    static let clockToggleClickThrough = Notification.Name("ClockOverlay.toggleClickThrough")
    static let clockOpenSettings = Notification.Name("ClockOverlay.openSettings")
    static let clockQuit = Notification.Name("ClockOverlay.quit")
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = SettingsStore()
    private var panel: OverlayPanel!
    private var statusItem: NSStatusItem!
    private var settingsPopover: NSPopover?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPanel()
        observeInternalNotifications()
    }

    func applicationWillTerminate(_ notification: Notification) {
        store.windowOrigin = panel?.frame.origin
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

    @objc private func showSettings() {
        if settingsPopover == nil {
            let popover = NSPopover()
            popover.behavior = .transient
            let view = SettingsView(store: store) { [weak self] enabled in
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
        let hosting = NSHostingController(rootView: ClockView(store: store))
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
        }

        panel.orderFrontRegardless()
    }

    private func restoredOrigin(for size: NSSize) -> CGPoint {
        if let saved = store.windowOrigin {
            let frame = NSRect(origin: saved, size: size)
            if NSScreen.screens.contains(where: { $0.frame.intersects(frame) }) {
                return saved
            }
        }
        guard let screen = NSScreen.main else { return .zero }
        let margin: CGFloat = 40
        return CGPoint(x: screen.visibleFrame.maxX - size.width - margin,
                       y: screen.visibleFrame.maxY - size.height - margin)
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
}
