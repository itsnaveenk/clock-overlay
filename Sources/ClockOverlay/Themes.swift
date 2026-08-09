import SwiftUI
import AppKit

enum BackgroundStyle: String, CaseIterable, Identifiable {
    case transparent
    case solid
    case frosted

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .transparent: "Transparent"
        case .solid: "Solid box"
        case .frosted: "Frosted glass"
        }
    }
}

struct ClockTheme: Identifiable {
    let id: String
    let name: String
    let foreground: Color
    let solidBackground: Color
}

enum ClockThemeCatalog {
    static let all: [ClockTheme] = [
        ClockTheme(
            id: "automatic", name: "Automatic",
            foreground: Color(nsColor: .labelColor),
            solidBackground: Color(nsColor: .windowBackgroundColor)
        ),
        ClockTheme(
            id: "midnight", name: "Midnight",
            foreground: Color(red: 1, green: 1, blue: 1),
            solidBackground: Color(red: 0.11, green: 0.13, blue: 0.18)
        ),
        ClockTheme(
            id: "cloud", name: "Cloud",
            foreground: Color(red: 0.10, green: 0.11, blue: 0.15),
            solidBackground: Color(red: 0.94, green: 0.95, blue: 0.97)
        ),
        ClockTheme(
            id: "terminal", name: "Terminal",
            foreground: Color(red: 0.29, green: 0.96, blue: 0.15),
            solidBackground: Color(red: 0.03, green: 0.06, blue: 0.04)
        ),
        ClockTheme(
            id: "neon", name: "Neon",
            foreground: Color(red: 0.13, green: 0.89, blue: 1.0),
            solidBackground: Color(red: 0.07, green: 0.08, blue: 0.12)
        ),
        ClockTheme(
            id: "paper", name: "Paper",
            foreground: Color(red: 0.18, green: 0.14, blue: 0.08),
            solidBackground: Color(red: 0.96, green: 0.93, blue: 0.85)
        ),
    ]

    static let customID = "custom"

    static func theme(id: String) -> ClockTheme {
        all.first { $0.id == id } ?? all[0]
    }
}

struct ThemeAppearance {
    let foreground: Color
    let backgroundStyle: BackgroundStyle
    let solidBackground: Color
}

struct FrostedGlass: NSViewRepresentable {
    var cornerRadius: CGFloat = 0

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        view.wantsLayer = true
        view.layer?.cornerRadius = cornerRadius
        view.layer?.masksToBounds = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.layer?.cornerRadius = cornerRadius
    }
}
