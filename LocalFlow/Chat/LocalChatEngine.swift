import Foundation
import NaturalLanguage
#if canImport(FoundationModels)
import FoundationModels
#endif

actor LocalChatEngine {
    private let historyStore: HistoryStore

    init(historyStore: HistoryStore) {
        self.historyStore = historyStore
    }

    // Returns (response text, used LLM)
    func respond(to query: String) async throws -> String {
        let context = await buildContext(for: query)
        let prompt = buildPrompt(query: query, context: context)

        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            return try await generateWithFoundationModels(prompt: prompt)
        }
        #endif

        return retrievalOnlyResponse(query: query, context: context)
    }

    // MARK: - RAG retrieval

    private func buildContext(for query: String) async -> String {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(query)
        let lang = recognizer.dominantLanguage?.rawValue ?? "es"

        guard let queryVec = await EmbeddingEngine.shared.embed(query, language: lang) else {
            return await topRecordsFallback()
        }

        let index = await MainActor.run { historyStore.semanticIndex }
        let records = await MainActor.run { historyStore.records }

        var scored: [(TranscriptionRecord, Float)] = []
        for record in records {
            var best: Float = 0
            for chunkVec in index[record.id] ?? [] {
                let s = EmbeddingEngine.cosine(queryVec, chunkVec)
                if s > best { best = s }
            }
            if best > 0 { scored.append((record, best)) }
        }

        let top = scored.sorted { $0.1 > $1.1 }.prefix(5).map(\.0)
        let fallback = await MainActor.run { Array(records.prefix(5)) }
        return formatRecords(top.isEmpty ? fallback : Array(top))
    }

    private func topRecordsFallback() async -> String {
        let records = await MainActor.run { historyStore.records }
        return formatRecords(Array(records.prefix(5)))
    }

    private func formatRecords(_ records: [TranscriptionRecord]) -> String {
        guard !records.isEmpty else { return "(sin transcripciones disponibles)" }
        return records.map { r in
            let date = r.timestamp.formatted(.dateTime.day().month().hour().minute())
            return "[\(date)] \(r.text)"
        }.joined(separator: "\n---\n")
    }

    private func buildPrompt(query: String, context: String) -> String {
        """
        Eres un asistente personal con acceso a las notas de voz del usuario, transcritas localmente en su Mac.

        Transcripciones relevantes:
        ---
        \(context)
        ---

        Responde en el mismo idioma que use el usuario. Si la respuesta no está en el contexto, indícalo claramente en lugar de inventar información.

        Pregunta: \(query)
        """
    }

    // MARK: - LLM generation

    #if canImport(FoundationModels)
    @available(macOS 26.0, *)
    private func generateWithFoundationModels(prompt: String) async throws -> String {
        let session = LanguageModelSession()
        let response = try await session.respond(to: prompt)
        return response.content
    }
    #endif

    // MARK: - Retrieval-only fallback (macOS < 26.0 or FoundationModels unavailable)

    private func retrievalOnlyResponse(query: String, context: String) -> String {
        """
        [Modo solo recuperación — Apple Intelligence no disponible]

        Transcripciones más relevantes para "\(query)":

        \(context)
        """
    }
}
