import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var store: SettingsStore
    @ObservedObject var engine: Engine
    @ObservedObject var recorder: SessionRecorder
    var onToggleClickThrough: (Bool) -> Void = { _ in }
    @State private var loginError: String?

    var body: some View {
        ScrollView {
            Form {
                modeSection
                timerSection
                appearanceSection
                behaviorSection
                sessionsSection
            }
            .formStyle(.grouped)
        }
        .frame(width: 380)
    }

    // MARK: - Mode

    private var modeSection: some View {
        Section("Mode") {
            Picker("Clock mode", selection: $store.mode) {
                ForEach(ClockMode.allCases) { mode in
                    Label(mode.displayName, systemImage: mode.systemImage).tag(mode.rawValue)
                }
            }
            Toggle("Double-click clock to cycle modes", isOn: $store.doubleClickCyclesModes)
        }
    }

    // MARK: - Timers

    private var timerSection: some View {
        Section("Timers") {
            Stepper("Countdown: \(minuteLabel(engine.countdownDuration))",
                    value: countdownMinutes, in: 1...240)
            Stepper("Pomodoro work: \(minuteLabel(engine.pomodoroWork))",
                    value: pomodoroWorkMinutes, in: 1...120)
            Stepper("Pomodoro break: \(minuteLabel(engine.pomodoroBreak))",
                    value: pomodoroBreakMinutes, in: 1...60)
            HStack {
                Text("Laser focus")
                Spacer()
                ForEach([25, 50, 90], id: \.self) { minutes in
                    Button("\(minutes)") {
                        engine.setFocusDuration(Double(minutes) * 60)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            Stepper("Focus: \(minuteLabel(engine.focusDuration))",
                    value: focusMinutes, in: 5...300)
        }
    }

    private var countdownMinutes: Binding<Double> {
        Binding(
            get: { engine.countdownDuration / 60 },
            set: { engine.setCountdownDuration($0 * 60) }
        )
    }

    private var pomodoroWorkMinutes: Binding<Double> {
        Binding(
            get: { engine.pomodoroWork / 60 },
            set: { engine.setPomodoroWork($0 * 60) }
        )
    }

    private var pomodoroBreakMinutes: Binding<Double> {
        Binding(
            get: { engine.pomodoroBreak / 60 },
            set: { engine.setPomodoroBreak($0 * 60) }
        )
    }

    private var focusMinutes: Binding<Double> {
        Binding(
            get: { engine.focusDuration / 60 },
            set: { engine.setFocusDuration($0 * 60) }
        )
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: $store.appearanceTheme) {
                ForEach(ClockThemeCatalog.all) { theme in
                    HStack(spacing: 6) {
                        Circle().fill(theme.foreground).frame(width: 10, height: 10)
                        Text(theme.name)
                    }
                    .tag(theme.id)
                }
                HStack(spacing: 6) {
                    Circle().fill(Color(hex: store.customFgHex)).frame(width: 10, height: 10)
                    Text("Custom")
                }
                .tag(ClockThemeCatalog.customID)
            }

            Picker("Background", selection: $store.backgroundStyle) {
                ForEach(BackgroundStyle.allCases) { style in
                    Text(style.displayName).tag(style.rawValue)
                }
            }

            if store.appearanceTheme == ClockThemeCatalog.customID {
                ColorPicker("Text color", selection: customFgBinding)
                ColorPicker("Background color", selection: customBgBinding)
            }

            FontPickerButton(fontName: store.customFontName) { name in
                store.customFontName = name
            }

            HStack(spacing: 10) {
                Text("Size").frame(width: 58, alignment: .leading)
                Slider(value: $store.fontSize, in: 20...96, step: 2)
                Text("\(Int(store.fontSize))")
                    .font(.caption).monospacedDigit()
                    .frame(width: 30, alignment: .trailing)
            }

            HStack(spacing: 10) {
                Text("Opacity").frame(width: 58, alignment: .leading)
                Slider(value: $store.opacity, in: 0.25...1.0, step: 0.05)
                Text("\(Int(store.opacity * 100))%")
                    .font(.caption).monospacedDigit()
                    .frame(width: 34, alignment: .trailing)
            }
        }
    }

    private var customFgBinding: Binding<Color> {
        Binding(
            get: { Color(hex: store.customFgHex) },
            set: { store.customFgHex = $0.hexString }
        )
    }

    private var customBgBinding: Binding<Color> {
        Binding(
            get: { Color(hex: store.customBgHex) },
            set: { store.customBgHex = $0.hexString }
        )
    }

    // MARK: - Behavior

    private var behaviorSection: some View {
        Section("Behavior") {
            Toggle("Click-through mode", isOn: clickThroughBinding)
            Toggle("Auto-hide in fullscreen apps", isOn: $store.autoHideInFullscreen)
            Toggle("Snap to screen edges", isOn: $store.edgeSnapping)
            Toggle("Fade out when idle", isOn: $store.idleFade)
            Toggle("Launch at Login", isOn: loginBinding)
            if let loginError {
                Text(loginError).font(.caption).foregroundStyle(.red)
            }
        }
    }

    private var clickThroughBinding: Binding<Bool> {
        Binding(
            get: { store.clickThrough },
            set: { newValue in
                store.clickThrough = newValue
                onToggleClickThrough(newValue)
            }
        )
    }

    private var loginBinding: Binding<Bool> {
        Binding(
            get: { store.launchesAtLogin },
            set: { newValue in
                loginError = nil
                do {
                    try store.setLaunchAtLogin(newValue)
                } catch {
                    loginError = error.localizedDescription
                }
            }
        )
    }

    // MARK: - Sessions

    private var sessionsSection: some View {
        Section("Sessions") {
            LabeledContent("Today", value: formatDuration(recorder.todayTotal))
            LabeledContent("This week", value: formatDuration(recorder.weekTotal))
            if recorder.sessions.isEmpty {
                Text("Completed focus, pomodoro, and countdown sessions appear here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(recorder.sessions.sorted(by: { $0.start > $1.start }).prefix(12)) { session in
                    LabeledContent(
                        "\(session.label)",
                        value: "\(formatShortDate(session.start)) · \(formatDuration(session.duration))"
                    )
                }
                Button("Clear history", role: .destructive) {
                    recorder.clear()
                }
            }
        }
    }

    // MARK: - Helpers

    private func minuteLabel(_ seconds: TimeInterval) -> String {
        let minutes = Int((seconds / 60).rounded())
        return "\(minutes) min"
    }
}

struct FontPickerButton: NSViewRepresentable {
    var fontName: String
    var onChange: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSButton {
        let button = NSButton(title: "Font…", target: context.coordinator, action: #selector(Coordinator.showFontPanel(_:)))
        button.bezelStyle = .rounded
        button.controlSize = .regular
        return button
    }

    func updateNSView(_ nsView: NSButton, context: Context) {
        context.coordinator.parent = self
        nsView.title = fontName.isEmpty ? "Default font" : fontName
    }

    final class Coordinator: NSObject {
        var parent: FontPickerButton

        init(_ parent: FontPickerButton) {
            self.parent = parent
        }

        @objc func showFontPanel(_ sender: Any?) {
            let manager = NSFontManager.shared
            manager.target = self
            manager.action = #selector(changeFont(_:))
            let current = parent.fontName.isEmpty
                ? NSFont.systemFont(ofSize: 13)
                : (NSFont(name: parent.fontName, size: 13) ?? NSFont.systemFont(ofSize: 13))
            manager.setSelectedFont(current, isMultiple: false)
            manager.orderFrontFontPanel(nil)
        }

        @objc func changeFont(_ sender: NSFontManager) {
            let selected = sender.selectedFont ?? NSFont.systemFont(ofSize: 13)
            let font = sender.convert(selected)
            parent.onChange(font.fontName)
        }
    }
}

func formatDuration(_ interval: TimeInterval) -> String {
    let total = Int(interval)
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    let seconds = total % 60
    if hours > 0 {
        return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
    }
    if minutes > 0 {
        return seconds > 0 ? "\(minutes)m \(seconds)s" : "\(minutes)m"
    }
    return "\(seconds)s"
}

func formatShortDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d, HH:mm"
    return formatter.string(from: date)
}
