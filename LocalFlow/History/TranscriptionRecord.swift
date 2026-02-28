import Foundation

enum RecordSource: String, Codable {
    case voice
    case appCapture
}

struct TranscriptionRecord: Codable, Identifiable {
    let id: UUID
    let text: String
    let timestamp: Date
    let wordCount: Int
    let durationSeconds: Double
    let language: String
    let targetApp: String?
    let source: RecordSource

    init(text: String, timestamp: Date = .now, durationSeconds: Double, language: String, targetApp: String? = nil, source: RecordSource = .voice) {
        self.id = UUID()
        self.text = text
        self.timestamp = timestamp
        self.wordCount = text.split(separator: " ").count
        self.durationSeconds = durationSeconds
        self.language = language
        self.targetApp = targetApp
        self.source = source
    }

    private enum CodingKeys: String, CodingKey {
        case id, text, timestamp, wordCount, durationSeconds, language, targetApp, source
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        wordCount = try container.decode(Int.self, forKey: .wordCount)
        durationSeconds = try container.decode(Double.self, forKey: .durationSeconds)
        language = try container.decode(String.self, forKey: .language)
        targetApp = try container.decodeIfPresent(String.self, forKey: .targetApp)
        source = try container.decodeIfPresent(RecordSource.self, forKey: .source) ?? .voice
    }
}
