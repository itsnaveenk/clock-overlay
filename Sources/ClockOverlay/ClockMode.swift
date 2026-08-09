import Foundation

enum ClockMode: String, CaseIterable, Identifiable {
    case digital
    case analog
    case stopwatch
    case countdown
    case pomodoro
    case focus

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .digital: "Digital"
        case .analog: "Analog"
        case .stopwatch: "Stopwatch"
        case .countdown: "Countdown"
        case .pomodoro: "Pomodoro"
        case .focus: "Laser Focus"
        }
    }

    var systemImage: String {
        switch self {
        case .digital: "digitalcrown.arrow.clockwise"
        case .analog: "clock"
        case .stopwatch: "stopwatch"
        case .countdown: "timer"
        case .pomodoro: "timer.circle"
        case .focus: "scope"
        }
    }
}
