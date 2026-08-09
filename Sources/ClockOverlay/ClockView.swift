import SwiftUI
import AppKit

struct ClockView: View {
    @ObservedObject var store: SettingsStore

    @State private var now = Date()
    @State private var window: NSWindow?

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private static let time12: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm:ss a"
        return f
    }()
    private static let time24: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()
    private static let dateFormat: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE MMM d"
        return f
    }()

    private var timeString: String {
        let f = store.use24h ? Self.time24 : Self.time12
        return f.string(from: now)
    }

    private var dateString: String {
        Self.dateFormat.string(from: now)
    }

    private var palette: (fg: Color, bg: Color) {
        switch Theme(rawValue: store.theme) ?? .automatic {
        case .light: return (.black, .white)
        case .dark: return (.white, .black)
        case .automatic:
            return (.primary, Color(nsColor: .windowBackgroundColor))
        }
    }

    var body: some View {
        VStack(spacing: 3) {
            Text(timeString)
                .font(.system(size: store.fontSize, weight: .semibold, design: .monospaced))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.2), value: timeString)
                .shadow(
                    color: store.transparentBackground ? .black.opacity(0.55) : .clear,
                    radius: 2, x: 0, y: 1
                )

            if store.showDate {
                Text(dateString.uppercased())
                    .font(.system(size: max(store.fontSize * 0.32, 11), weight: .semibold, design: .rounded))
                    .opacity(0.85)
                    .monospacedDigit()
            }
        }
        .foregroundStyle(palette.fg)
        .padding(.horizontal, store.fontSize * 0.5)
        .padding(.vertical, store.fontSize * 0.35)
        .background(clockBackground)
        .overlay(clockBorder)
        .shadow(color: store.transparentBackground ? .clear : .black.opacity(0.3), radius: 8, x: 0, y: 3)
        .padding(14)
        .onReceive(timer) { now = $0 }
        .onChange(of: store.fontSize) { _, _ in resizeToFit() }
        .background(WindowAccessor { window = $0 })
        .contextMenu { clockContextMenu }
    }

    @ViewBuilder
    private var clockBackground: some View {
        if store.transparentBackground {
            Color.clear
        } else {
            RoundedRectangle(cornerRadius: store.fontSize * 0.3, style: .continuous)
                .fill(palette.bg.opacity(store.opacity))
        }
    }

    @ViewBuilder
    private var clockBorder: some View {
        if !store.transparentBackground {
            RoundedRectangle(cornerRadius: store.fontSize * 0.3, style: .continuous)
                .strokeBorder(palette.fg.opacity(0.15), lineWidth: 1)
        }
    }

    private var clockContextMenu: some View {
        VStack {
            Toggle("24-Hour Format", isOn: $store.use24h)
            Toggle("Show Seconds", isOn: $store.showSeconds)
            Toggle("Show Date", isOn: $store.showDate)
            Divider()
            Button("Settings…") {
                NotificationCenter.default.post(name: .clockOpenSettings, object: nil)
            }
            Button(store.clickThrough ? "Disable Click-Through" : "Enable Click-Through") {
                NotificationCenter.default.post(name: .clockToggleClickThrough, object: nil)
            }
            Divider()
            Button("Quit Clock Overlay", role: .destructive) {
                NotificationCenter.default.post(name: .clockQuit, object: nil)
            }
        }
    }

    private func resizeToFit() {
        guard let window, let controller = window.contentViewController else { return }
        window.setContentSize(controller.view.fittingSize)
    }
}
