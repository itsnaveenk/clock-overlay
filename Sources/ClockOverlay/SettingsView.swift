import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: SettingsStore
    var onToggleClickThrough: (Bool) -> Void = { _ in }
    @State private var loginError: String?

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Display") {
                    Toggle("24-Hour Format", isOn: $store.use24h)
                    Toggle("Show Seconds", isOn: $store.showSeconds)
                    Toggle("Show Date", isOn: $store.showDate)
                }

                Section("Appearance") {
                    Picker("Theme", selection: $store.theme) {
                        ForEach(Theme.allCases) { theme in
                            Text(theme.displayName).tag(theme.rawValue)
                        }
                    }
                    Toggle("Transparent Background", isOn: $store.transparentBackground)
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

                Section("Window") {
                    Toggle("Click-Through Mode", isOn: clickThroughBinding)
                    Text("Lets clicks pass through to apps underneath. Disable it from the menu bar to drag the clock again.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("General") {
                    Toggle("Launch at Login", isOn: loginBinding)
                    if let loginError {
                        Text(loginError).font(.caption).foregroundStyle(.red)
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 360)
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
}
