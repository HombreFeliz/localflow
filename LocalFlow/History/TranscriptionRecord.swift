import Foundation

struct TranscriptionRecord: Codable, Identifiable {
    let id: UUID
    let text: String
    let timestamp: Date
    let wordCount: Int
    let durationSeconds: Double
    let language: String

    init(text: String, timestamp: Date = .now, durationSeconds: Double, language: String) {
        self.id = UUID()
        self.text = text
        self.timestamp = timestamp
        self.wordCount = text.split(separator: " ").count
        self.durationSeconds = durationSeconds
        self.language = language
    }
}
