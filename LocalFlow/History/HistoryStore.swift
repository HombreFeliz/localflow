import Foundation

@MainActor
@Observable
final class HistoryStore {
    nonisolated init() {}

    private(set) var records: [TranscriptionRecord] = []

    // MARK: - Semantic index (in-memory, not persisted)

    private(set) var semanticIndex: [UUID: [[Float]]] = [:]

    func updateSemanticIndex(_ index: [UUID: [[Float]]]) {
        semanticIndex.merge(index) { _, new in new }
    }

    func addToSemanticIndex(id: UUID, vectors: [[Float]]) {
        semanticIndex[id] = vectors
    }

    // MARK: - Computed stats

    var totalWords: Int {
        records.reduce(0) { $0 + $1.wordCount }
    }

    var averageWPM: Int {
        let valid = records.filter { $0.durationSeconds > 0 }
        guard !valid.isEmpty else { return 0 }
        let total = valid.reduce(0.0) { $0 + Double($1.wordCount) / $1.durationSeconds * 60 }
        return Int(total / Double(valid.count))
    }

    var streakDays: Int {
        guard !records.isEmpty else { return 0 }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        var streak = 0
        var current = today

        while true {
            let hasRecord = records.contains {
                calendar.startOfDay(for: $0.timestamp) == current
            }
            guard hasRecord else { break }
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: current) else { break }
            current = prev
        }
        return streak
    }

    // MARK: - Persistence

    private var storageURL: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = support.appending(path: "LocalFlow", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appending(path: "history.json")
    }

    func load() {
        guard let data = try? Data(contentsOf: storageURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        records = (try? decoder.decode([TranscriptionRecord].self, from: data)) ?? []
    }

    func append(_ record: TranscriptionRecord) {
        records.insert(record, at: 0)
        save()
    }

    func delete(id: UUID) {
        records.removeAll { $0.id == id }
        save()
    }

    func clear() {
        records = []
        save()
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        try? encoder.encode(records).write(to: storageURL)
    }
}
