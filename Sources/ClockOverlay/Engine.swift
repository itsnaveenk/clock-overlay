import Foundation
import Combine

enum PomodoroPhase: Equatable {
    case work
    case rest
}

final class Engine: ObservableObject {
    let recorder = SessionRecorder()

    // Stopwatch
    @Published private(set) var stopwatchElapsed: TimeInterval = 0
    @Published private(set) var stopwatchRunning = false

    // Countdown
    @Published var countdownDuration: TimeInterval = 25 * 60
    @Published private(set) var countdownRemaining: TimeInterval = 25 * 60
    @Published private(set) var countdownRunning = false

    // Pomodoro
    @Published var pomodoroWork: TimeInterval = 25 * 60
    @Published var pomodoroBreak: TimeInterval = 5 * 60
    @Published private(set) var pomodoroPhase: PomodoroPhase = .work
    @Published private(set) var pomodoroRemaining: TimeInterval = 25 * 60
    @Published private(set) var pomodoroRunning = false
    @Published private(set) var pomodoroCompleted = 0

    // Laser focus
    @Published var focusDuration: TimeInterval = 25 * 60
    @Published private(set) var focusRemaining: TimeInterval = 25 * 60
    @Published private(set) var focusRunning = false

    var onSessionComplete: ((_ type: String, _ label: String) -> Void)?

    private var timer: Timer?
    private var stopwatchStart: Date?
    private var countdownStart: Date?
    private var pomodoroStart: Date?
    private var focusStart: Date?

    init() {
        let ticker = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(ticker, forMode: .common)
        timer = ticker
    }

    // MARK: - Stopwatch

    func toggleStopwatch() {
        stopwatchRunning ? pauseStopwatch() : startStopwatch()
    }

    func startStopwatch() {
        guard !stopwatchRunning else { return }
        stopwatchStart = Date().addingTimeInterval(-stopwatchElapsed)
        stopwatchRunning = true
    }

    func pauseStopwatch() {
        guard stopwatchRunning, let start = stopwatchStart else { return }
        stopwatchElapsed = Date().timeIntervalSince(start)
        stopwatchRunning = false
        stopwatchStart = nil
    }

    func resetStopwatch() {
        stopwatchElapsed = 0
        stopwatchRunning = false
        stopwatchStart = nil
    }

    // MARK: - Duration setters

    func setCountdownDuration(_ duration: TimeInterval) {
        countdownDuration = duration
        if countdownRemaining > duration || !countdownRunning {
            countdownRemaining = duration
        }
    }

    func setPomodoroWork(_ duration: TimeInterval) {
        pomodoroWork = duration
        if pomodoroPhase == .work, !pomodoroRunning {
            pomodoroRemaining = duration
        }
    }

    func setPomodoroBreak(_ duration: TimeInterval) {
        pomodoroBreak = duration
        if pomodoroPhase == .rest, !pomodoroRunning {
            pomodoroRemaining = duration
        }
    }

    func setFocusDuration(_ duration: TimeInterval) {
        focusDuration = duration
        if focusRemaining > duration || !focusRunning {
            focusRemaining = duration
        }
    }

    // MARK: - Countdown

    func startCountdown() {
        guard !countdownRunning else { return }
        if countdownRemaining <= 0 { countdownRemaining = countdownDuration }
        countdownStart = Date().addingTimeInterval(-(countdownDuration - countdownRemaining))
        countdownRunning = true
    }

    func pauseCountdown() {
        guard countdownRunning, let start = countdownStart else { return }
        countdownRemaining = max(0, countdownDuration - Date().timeIntervalSince(start))
        countdownRunning = false
        countdownStart = nil
    }

    func resetCountdown() {
        countdownRemaining = countdownDuration
        countdownRunning = false
        countdownStart = nil
    }

    private func finishCountdown() {
        countdownRunning = false
        countdownStart = nil
        let end = Date()
        recorder.record(type: "countdown", label: "Countdown", start: end.addingTimeInterval(-countdownDuration), end: end)
        onSessionComplete?("countdown", "Countdown finished")
    }

    // MARK: - Pomodoro

    func startPomodoro() {
        guard !pomodoroRunning else { return }
        if pomodoroRemaining <= 0 { pomodoroRemaining = currentPomodoroDuration }
        pomodoroStart = Date().addingTimeInterval(-(currentPomodoroDuration - pomodoroRemaining))
        pomodoroRunning = true
    }

    func pausePomodoro() {
        guard pomodoroRunning, let start = pomodoroStart else { return }
        pomodoroRemaining = max(0, currentPomodoroDuration - Date().timeIntervalSince(start))
        pomodoroRunning = false
        pomodoroStart = nil
    }

    func resetPomodoro() {
        pomodoroPhase = .work
        pomodoroRemaining = pomodoroWork
        pomodoroRunning = false
        pomodoroStart = nil
    }

    private var currentPomodoroDuration: TimeInterval {
        pomodoroPhase == .work ? pomodoroWork : pomodoroBreak
    }

    private func advancePomodoro() {
        let end = Date()
        if pomodoroPhase == .work {
            pomodoroCompleted += 1
            recorder.record(type: "pomodoro", label: "Pomodoro \(pomodoroCompleted)", start: end.addingTimeInterval(-pomodoroWork), end: end)
            onSessionComplete?("pomodoro", "Work block complete — take a break")
            pomodoroPhase = .rest
            pomodoroRemaining = pomodoroBreak
        } else {
            onSessionComplete?("pomodoro", "Break over — back to work")
            pomodoroPhase = .work
            pomodoroRemaining = pomodoroWork
        }
        pomodoroStart = Date()
        pomodoroRunning = true
    }

    // MARK: - Laser focus

    func startFocus() {
        guard !focusRunning else { return }
        if focusRemaining <= 0 { focusRemaining = focusDuration }
        focusStart = Date().addingTimeInterval(-(focusDuration - focusRemaining))
        focusRunning = true
    }

    func pauseFocus() {
        guard focusRunning, let start = focusStart else { return }
        focusRemaining = max(0, focusDuration - Date().timeIntervalSince(start))
        focusRunning = false
        focusStart = nil
    }

    func resetFocus() {
        focusRemaining = focusDuration
        focusRunning = false
        focusStart = nil
    }

    private func finishFocus() {
        focusRunning = false
        focusStart = nil
        let end = Date()
        recorder.record(type: "focus", label: "Focus session", start: end.addingTimeInterval(-focusDuration), end: end)
        onSessionComplete?("focus", "Focus session complete")
    }

    // MARK: - Tick

    private func tick() {
        let now = Date()

        if stopwatchRunning, let start = stopwatchStart {
            stopwatchElapsed = now.timeIntervalSince(start)
        }
        if countdownRunning, let start = countdownStart {
            let remaining = countdownDuration - now.timeIntervalSince(start)
            if remaining <= 0 {
                countdownRemaining = 0
                finishCountdown()
            } else {
                countdownRemaining = remaining
            }
        }
        if pomodoroRunning, let start = pomodoroStart {
            let remaining = currentPomodoroDuration - now.timeIntervalSince(start)
            if remaining <= 0 {
                pomodoroRemaining = 0
                advancePomodoro()
            } else {
                pomodoroRemaining = remaining
            }
        }
        if focusRunning, let start = focusStart {
            let remaining = focusDuration - now.timeIntervalSince(start)
            if remaining <= 0 {
                focusRemaining = 0
                finishFocus()
            } else {
                focusRemaining = remaining
            }
        }
    }
}

// MARK: - Formatting

func formatClock(_ interval: TimeInterval) -> String {
    let total = max(0, Int(interval))
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    let seconds = total % 60
    if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }
    return String(format: "%02d:%02d", minutes, seconds)
}
