import SwiftUI
import Combine
import ServiceManagement

final class SettingsStore: ObservableObject {
    // Display
    @Published var showSeconds: Bool { didSet { persist() } }
    @Published var showDate: Bool { didSet { persist() } }
    @Published var use24h: Bool { didSet { persist() } }

    // Mode
    @Published var mode: String { didSet { persist() } }
    @Published var doubleClickCyclesModes: Bool { didSet { persist() } }

    // Appearance
    @Published var fontSize: Double { didSet { persist() } }
    @Published var opacity: Double { didSet { persist() } }
    @Published var appearanceTheme: String { didSet { persist() } }
    @Published var backgroundStyle: String { didSet { persist() } }
    @Published var customFgHex: String { didSet { persist() } }
    @Published var customBgHex: String { didSet { persist() } }
    @Published var customFontName: String { didSet { persist() } }

    // Behavior
    @Published var clickThrough: Bool { didSet { persist() } }
    @Published var autoHideInFullscreen: Bool { didSet { persist() } }
    @Published var edgeSnapping: Bool { didSet { persist() } }
    @Published var idleFade: Bool { didSet { persist() } }

    // Login
    @Published var launchesAtLogin: Bool

    // Window
    @Published var windowOrigin: CGPoint? { didSet { persist() } }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        showSeconds = defaults.object(forKey: Keys.showSeconds) as? Bool ?? true
        showDate = defaults.object(forKey: Keys.showDate) as? Bool ?? true
        use24h = defaults.object(forKey: Keys.use24h) as? Bool ?? false

        mode = defaults.string(forKey: Keys.mode) ?? ClockMode.digital.rawValue
        doubleClickCyclesModes = defaults.object(forKey: Keys.doubleClickCyclesModes) as? Bool ?? false

        fontSize = defaults.object(forKey: Keys.fontSize) as? Double ?? 40
        opacity = defaults.object(forKey: Keys.opacity) as? Double ?? 0.85
        appearanceTheme = defaults.string(forKey: Keys.appearanceTheme) ?? "automatic"
        backgroundStyle = defaults.string(forKey: Keys.backgroundStyle) ?? BackgroundStyle.transparent.rawValue
        customFgHex = defaults.string(forKey: Keys.customFgHex) ?? "#ffffff"
        customBgHex = defaults.string(forKey: Keys.customBgHex) ?? "#1d222b"
        customFontName = defaults.string(forKey: Keys.customFontName) ?? ""

        clickThrough = defaults.object(forKey: Keys.clickThrough) as? Bool ?? false
        autoHideInFullscreen = defaults.object(forKey: Keys.autoHideInFullscreen) as? Bool ?? false
        edgeSnapping = defaults.object(forKey: Keys.edgeSnapping) as? Bool ?? false
        idleFade = defaults.object(forKey: Keys.idleFade) as? Bool ?? false

        launchesAtLogin = SMAppService.mainApp.status == .enabled
        if let data = defaults.data(forKey: Keys.windowOrigin) {
            windowOrigin = try? JSONDecoder().decode(CGPoint.self, from: data)
        }
    }

    var currentMode: ClockMode {
        ClockMode(rawValue: mode) ?? .digital
    }

    var appearance: ThemeAppearance {
        let style = BackgroundStyle(rawValue: backgroundStyle) ?? .transparent
        if appearanceTheme == ClockThemeCatalog.customID {
            return ThemeAppearance(
                foreground: Color(hex: customFgHex),
                backgroundStyle: style,
                solidBackground: Color(hex: customBgHex)
            )
        }
        let theme = ClockThemeCatalog.theme(id: appearanceTheme)
        return ThemeAppearance(
            foreground: theme.foreground,
            backgroundStyle: style,
            solidBackground: theme.solidBackground
        )
    }

    func clockFont(size: CGFloat) -> Font {
        if !customFontName.isEmpty {
            return Font.custom(customFontName, size: size)
        }
        return .system(size: size, weight: .semibold, design: .monospaced)
    }

    func setLaunchAtLogin(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
        launchesAtLogin = SMAppService.mainApp.status == .enabled
    }

    private func persist() {
        defaults.set(showSeconds, forKey: Keys.showSeconds)
        defaults.set(showDate, forKey: Keys.showDate)
        defaults.set(use24h, forKey: Keys.use24h)

        defaults.set(mode, forKey: Keys.mode)
        defaults.set(doubleClickCyclesModes, forKey: Keys.doubleClickCyclesModes)

        defaults.set(fontSize, forKey: Keys.fontSize)
        defaults.set(opacity, forKey: Keys.opacity)
        defaults.set(appearanceTheme, forKey: Keys.appearanceTheme)
        defaults.set(backgroundStyle, forKey: Keys.backgroundStyle)
        defaults.set(customFgHex, forKey: Keys.customFgHex)
        defaults.set(customBgHex, forKey: Keys.customBgHex)
        defaults.set(customFontName, forKey: Keys.customFontName)

        defaults.set(clickThrough, forKey: Keys.clickThrough)
        defaults.set(autoHideInFullscreen, forKey: Keys.autoHideInFullscreen)
        defaults.set(edgeSnapping, forKey: Keys.edgeSnapping)
        defaults.set(idleFade, forKey: Keys.idleFade)

        if let origin = windowOrigin,
           let data = try? JSONEncoder().encode(origin) {
            defaults.set(data, forKey: Keys.windowOrigin)
        }
    }

    private enum Keys {
        static let showSeconds = "showSeconds"
        static let showDate = "showDate"
        static let use24h = "use24h"

        static let mode = "mode"
        static let doubleClickCyclesModes = "doubleClickCyclesModes"

        static let fontSize = "fontSize"
        static let opacity = "opacity"
        static let appearanceTheme = "appearanceTheme"
        static let backgroundStyle = "backgroundStyle"
        static let customFgHex = "customFgHex"
        static let customBgHex = "customBgHex"
        static let customFontName = "customFontName"

        static let clickThrough = "clickThrough"
        static let autoHideInFullscreen = "autoHideInFullscreen"
        static let edgeSnapping = "edgeSnapping"
        static let idleFade = "idleFade"

        static let windowOrigin = "windowOrigin"
    }
}

extension Color {
    init(hex: String) {
        var value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("#") { value.removeFirst() }
        var int: UInt64 = 0
        Scanner(string: value).scanHexInt64(&int)
        let r, g, b: Double
        if value.count == 6 {
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        } else {
            r = 1; g = 1; b = 1
        }
        self.init(red: r, green: g, blue: b)
    }

    var hexString: String {
        let nsColor = NSColor(self).usingColorSpace(.sRGB) ?? .white
        return String(format: "#%02X%02X%02X",
                      Int(round(nsColor.redComponent * 255)),
                      Int(round(nsColor.greenComponent * 255)),
                      Int(round(nsColor.blueComponent * 255)))
    }
}
