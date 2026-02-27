import NaturalLanguage
import Foundation

actor EmbeddingEngine {
    static let shared = EmbeddingEngine()
    private init() {}
    private var modelCache: [String: NLEmbedding] = [:]

    func embed(_ text: String, language: String) -> [Float]? {
        let lang: NLLanguage
        if language == "auto" {
            let recognizer = NLLanguageRecognizer()
            recognizer.processString(text)
            lang = recognizer.dominantLanguage ?? .english
        } else {
            lang = NLLanguage(rawValue: language)
        }
        let model = loadedModel(for: lang) ?? loadedModel(for: .english)
        guard let model, let vector = model.vector(for: text) else { return nil }
        return vector.map { Float($0) }
    }

    private func loadedModel(for language: NLLanguage) -> NLEmbedding? {
        if let cached = modelCache[language.rawValue] { return cached }
        if let model = NLEmbedding.sentenceEmbedding(for: language) {
            modelCache[language.rawValue] = model
            return model
        }
        return nil
    }

    static func chunkText(_ text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        var chunks: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let chunk = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if chunk.split(separator: " ").count >= 4 { chunks.append(chunk) }
            return true
        }
        return chunks.isEmpty ? [text] : chunks
    }

    static func cosine(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        var dot: Float = 0; var mA: Float = 0; var mB: Float = 0
        for i in 0..<a.count { dot += a[i]*b[i]; mA += a[i]*a[i]; mB += b[i]*b[i] }
        let d = sqrt(mA) * sqrt(mB)
        return d > 0 ? dot / d : 0
    }
}
