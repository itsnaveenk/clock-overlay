import SwiftUI
import Combine
import ServiceManagement

enum Theme: String, CaseIterable, Identifiable {
    case automatic, light, dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .automatic: "Automatic"
        case .light: "Light"
        case .dark: "Dark"
        }
    }
}

final class SettingsStore: ObservableObject {
    @Published var showSeconds: Bool { didSet { persist() } }
    @Published var showDate: Bool { didSet { persist() } }
    @Published var use24h: Bool { didSet { persist() } }
    @Published var fontSize: Double { didSet { persist() } }
    @Published var opacity: Double { didSet { persist() } }
    @Published var theme: String { didSet { persist() } }
    @Published var transparentBackground: Bool { didSet { persist() } }
    @Published var clickThrough: Bool { didSet { persist() } }
    @Published var launchesAtLogin: Bool
    @Published var windowOrigin: CGPoint? { didSet { persist() } }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        showSeconds = defaults.object(forKey: Keys.showSeconds) as? Bool ?? true
        showDate = defaults.object(forKey: Keys.showDate) as? Bool ?? true
        use24h = defaults.object(forKey: Keys.use24h) as? Bool ?? false
        fontSize = defaults.object(forKey: Keys.fontSize) as? Double ?? 40
        opacity = defaults.object(forKey: Keys.opacity) as? Double ?? 0.85
        theme = defaults.string(forKey: Keys.theme) ?? Theme.automatic.rawValue
        transparentBackground = defaults.object(forKey: Keys.transparentBackground) as? Bool ?? true
        clickThrough = defaults.object(forKey: Keys.clickThrough) as? Bool ?? false
        launchesAtLogin = SMAppService.mainApp.status == .enabled
        if let data = defaults.data(forKey: Keys.windowOrigin) {
            windowOrigin = try? JSONDecoder().decode(CGPoint.self, from: data)
        }
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
        defaults.set(fontSize, forKey: Keys.fontSize)
        defaults.set(opacity, forKey: Keys.opacity)
        defaults.set(theme, forKey: Keys.theme)
        defaults.set(transparentBackground, forKey: Keys.transparentBackground)
        defaults.set(clickThrough, forKey: Keys.clickThrough)
        if let origin = windowOrigin,
           let data = try? JSONEncoder().encode(origin) {
            defaults.set(data, forKey: Keys.windowOrigin)
        }
    }

    private enum Keys {
        static let showSeconds = "showSeconds"
        static let showDate = "showDate"
        static let use24h = "use24h"
        static let fontSize = "fontSize"
        static let opacity = "opacity"
        static let theme = "theme"
        static let transparentBackground = "transparentBackground"
        static let clickThrough = "clickThrough"
        static let windowOrigin = "windowOrigin"
    }
}
