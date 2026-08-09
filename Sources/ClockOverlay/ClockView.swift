import SwiftUI
import AppKit

struct ClockView: View {
    @ObservedObject var store: SettingsStore
    @ObservedObject var engine: Engine

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

    var body: some View {
        Group {
            switch store.currentMode {
            case .digital:
                digitalContent
            case .analog:
                AnalogClockView(store: store)
                    .padding(store.fontSize * 0.6)
            case .stopwatch:
                StopwatchView(engine: engine, store: store).modifier(chrome)
            case .countdown:
                CountdownView(engine: engine, store: store).modifier(chrome)
            case .pomodoro:
                PomodoroView(engine: engine, store: store).modifier(chrome)
            case .focus:
                FocusView(engine: engine, store: store).modifier(chrome)
            }
        }
        .padding(14)
        .onReceive(timer) { now = $0 }
        .onChange(of: store.fontSize) { _, _ in resizeToFit() }
        .onChange(of: store.mode) { _, _ in resizeToFit() }
        .onChange(of: store.customFontName) { _, _ in resizeToFit() }
        .onChange(of: store.showDate) { _, _ in resizeToFit() }
        .background(WindowAccessor { window = $0 })
        .contextMenu { clockContextMenu }
    }

    // MARK: - Digital

    private var digitalContent: some View {
        VStack(spacing: 3) {
            Text(timeString)
                .font(store.clockFont(size: store.fontSize))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.2), value: timeString)
                .shadow(
                    color: store.appearance.backgroundStyle == .transparent
                        ? .black.opacity(0.55)
                        : .clear,
                    radius: 2, x: 0, y: 1
                )

            if store.showDate {
                Text(dateString.uppercased())
                    .font(.system(size: max(store.fontSize * 0.32, 11), weight: .semibold, design: .rounded))
                    .opacity(0.85)
                    .monospacedDigit()
            }
        }
        .modifier(chrome)
    }

    // MARK: - Shared chrome

    private var chrome: ChromeModifier {
        ChromeModifier(store: store)
    }

    struct ChromeModifier: ViewModifier {
        @ObservedObject var store: SettingsStore

        func body(content: Content) -> some View {
            let appearance = store.appearance
            let isTransparent = appearance.backgroundStyle == .transparent
            content
                .foregroundStyle(appearance.foreground)
                .padding(.horizontal, store.fontSize * 0.5)
                .padding(.vertical, store.fontSize * 0.35)
                .background(background(appearance: appearance))
                .overlay(border(appearance: appearance))
                .shadow(color: isTransparent ? .clear : .black.opacity(0.3), radius: 8, x: 0, y: 3)
        }

        @ViewBuilder
        func background(appearance: ThemeAppearance) -> some View {
            switch appearance.backgroundStyle {
            case .transparent:
                Color.clear
            case .solid:
                RoundedRectangle(cornerRadius: store.fontSize * 0.3, style: .continuous)
                    .fill(appearance.solidBackground.opacity(store.opacity))
            case .frosted:
                FrostedGlass(cornerRadius: store.fontSize * 0.3)
            }
        }

        @ViewBuilder
        func border(appearance: ThemeAppearance) -> some View {
            if appearance.backgroundStyle != .transparent {
                RoundedRectangle(cornerRadius: store.fontSize * 0.3, style: .continuous)
                    .strokeBorder(appearance.foreground.opacity(0.12), lineWidth: 1)
            }
        }
    }

    // MARK: - Context menu

    private var clockContextMenu: some View {
        VStack {
            Menu {
                ForEach(ClockMode.allCases) { mode in
                    Button {
                        store.mode = mode.rawValue
                    } label: {
                        if store.mode == mode.rawValue {
                            Label(mode.displayName, systemImage: "checkmark")
                        } else {
                            Text(mode.displayName)
                        }
                    }
                }
            } label: {
                Label("Mode", systemImage: "arrow.left.arrow.right")
            }

            modeActions

            Divider()

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

    @ViewBuilder
    private var modeActions: some View {
        switch store.currentMode {
        case .digital, .analog:
            EmptyView()
        case .stopwatch:
            Button(engine.stopwatchRunning ? "Pause" : "Start") { engine.toggleStopwatch() }
            Button("Reset", role: .destructive) { engine.resetStopwatch() }
        case .countdown:
            Button(engine.countdownRunning ? "Pause" : "Start") {
                engine.countdownRunning ? engine.pauseCountdown() : engine.startCountdown()
            }
            Button("Reset", role: .destructive) { engine.resetCountdown() }
        case .pomodoro:
            Button(engine.pomodoroRunning ? "Pause" : "Start") {
                engine.pomodoroRunning ? engine.pausePomodoro() : engine.startPomodoro()
            }
            Button("Reset", role: .destructive) { engine.resetPomodoro() }
        case .focus:
            Button(engine.focusRunning ? "Pause" : "Start") {
                engine.focusRunning ? engine.pauseFocus() : engine.startFocus()
            }
            Button("Reset", role: .destructive) { engine.resetFocus() }
        }
    }

    private func resizeToFit() {
        guard let window, let controller = window.contentViewController else { return }
        window.setContentSize(controller.view.fittingSize)
    }
}
