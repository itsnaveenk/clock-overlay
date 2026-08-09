import SwiftUI

struct TimerDigitsView: View {
    @ObservedObject var store: SettingsStore
    let time: String
    let subtitle: String?
    var progress: Double? = nil

    var body: some View {
        VStack(spacing: 5) {
            Text(time)
                .font(store.clockFont(size: store.fontSize))
                .monospacedDigit()
                .contentTransition(.numericText())
                .foregroundStyle(store.appearance.foreground)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: max(store.fontSize * 0.3, 10), weight: .semibold, design: .rounded))
                    .foregroundStyle(store.appearance.foreground.opacity(0.8))
                    .textCase(.uppercase)
            }
            if let progress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(store.appearance.foreground.opacity(0.15))
                        Capsule().fill(store.appearance.foreground.opacity(0.9))
                            .frame(width: geo.size.width * progress)
                    }
                }
                .frame(width: store.fontSize * 4.5, height: 3)
            }
        }
    }
}

struct StopwatchView: View {
    @ObservedObject var engine: Engine
    @ObservedObject var store: SettingsStore

    var body: some View {
        TimerDigitsView(
            store: store,
            time: formatClock(engine.stopwatchElapsed),
            subtitle: engine.stopwatchRunning
                ? "Running"
                : (engine.stopwatchElapsed > 0 ? "Paused" : "Ready")
        )
    }
}

struct CountdownView: View {
    @ObservedObject var engine: Engine
    @ObservedObject var store: SettingsStore

    private var progress: Double {
        guard engine.countdownDuration > 0 else { return 0 }
        return max(0, min(1, engine.countdownRemaining / engine.countdownDuration))
    }

    var body: some View {
        TimerDigitsView(
            store: store,
            time: formatClock(engine.countdownRemaining),
            subtitle: engine.countdownRunning
                ? "Countdown"
                : (engine.countdownRemaining < engine.countdownDuration ? "Paused" : "Ready"),
            progress: progress
        )
    }
}

struct PomodoroView: View {
    @ObservedObject var engine: Engine
    @ObservedObject var store: SettingsStore

    private var progress: Double {
        let total = engine.pomodoroPhase == .work ? engine.pomodoroWork : engine.pomodoroBreak
        guard total > 0 else { return 0 }
        return max(0, min(1, engine.pomodoroRemaining / total))
    }

    var body: some View {
        TimerDigitsView(
            store: store,
            time: formatClock(engine.pomodoroRemaining),
            subtitle: phaseTitle,
            progress: progress
        )
    }

    private var phaseTitle: String {
        let phase = engine.pomodoroPhase == .work ? "Work" : "Break"
        if engine.pomodoroCompleted > 0 {
            return "\(phase) · \(engine.pomodoroCompleted)"
        }
        return phase
    }
}

struct FocusView: View {
    @ObservedObject var engine: Engine
    @ObservedObject var store: SettingsStore

    private var progress: Double {
        guard engine.focusDuration > 0 else { return 0 }
        return max(0, min(1, engine.focusRemaining / engine.focusDuration))
    }

    var body: some View {
        TimerDigitsView(
            store: store,
            time: formatClock(engine.focusRemaining),
            subtitle: engine.focusRunning
                ? "Focusing"
                : (engine.focusRemaining < engine.focusDuration ? "Paused" : "Ready"),
            progress: progress
        )
    }
}
