import Foundation

struct SessionRecord: Codable, Identifiable {
    let id: UUID
    let start: Date
    let end: Date
    let type: String
    let label: String

    var duration: TimeInterval { end.timeIntervalSince(start) }
}

final class SessionRecorder: ObservableObject {
    @Published private(set) var sessions: [SessionRecord] = []

    private let url: URL

    init() {
        let directory = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ClockOverlay", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        url = directory.appendingPathComponent("sessions.json")
        load()
    }

    func record(type: String, label: String, start: Date, end: Date) {
        guard end.timeIntervalSince(start) > 0 else { return }
        sessions.append(SessionRecord(id: UUID(), start: start, end: end, type: type, label: label))
        save()
    }

    var todayTotal: TimeInterval {
        sessions.filter { Calendar.current.isDateInToday($0.start) }.reduce(0) { $0 + $1.duration }
    }

    var todayCount: Int {
        sessions.filter { Calendar.current.isDateInToday($0.start) }.count
    }

    var weekTotal: TimeInterval {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return sessions.filter { $0.start >= startOfWeek }.reduce(0) { $0 + $1.duration }
    }

    func clear() {
        sessions.removeAll()
        save()
    }

    private func save() {
        let data = try? JSONEncoder().encode(sessions)
        try? data?.write(to: url, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: url) else { return }
        sessions = (try? JSONDecoder().decode([SessionRecord].self, from: data)) ?? []
    }
}
