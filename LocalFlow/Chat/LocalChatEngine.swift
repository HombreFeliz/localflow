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

    func respond(to query: String) async throws -> String {
        let (context, matchedRecords) = await buildContext(for: query)

        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            let prompt = buildPrompt(query: query, context: context)
            return try await generateWithFoundationModels(prompt: prompt)
        }
        #endif

        return smartFallbackResponse(query: query, records: matchedRecords)
    }

    // MARK: - RAG retrieval

    private func buildContext(for query: String) async -> (context: String, records: [TranscriptionRecord]) {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(query)
        let lang = recognizer.dominantLanguage?.rawValue ?? "es"

        guard let queryVec = await EmbeddingEngine.shared.embed(query, language: lang) else {
            let fallback = await topRecordsFallback()
            return (formatRecords(fallback), fallback)
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
        let result = top.isEmpty ? fallback : Array(top)
        return (formatRecords(result), result)
    }

    private func topRecordsFallback() async -> [TranscriptionRecord] {
        let records = await MainActor.run { historyStore.records }
        return Array(records.prefix(5))
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

    // MARK: - Smart fallback (macOS < 26.0)

    private func smartFallbackResponse(query: String, records: [TranscriptionRecord]) -> String {
        guard !records.isEmpty else {
            return "No encontré notas relacionadas con tu pregunta."
        }

        let q = query.lowercased()
        let now = Date()
        let cal = Calendar.current

        let isYesterday  = q.contains("ayer")
        let isToday      = q.contains("hoy")
        let isLastHour   = q.contains("última hora") || q.contains("hace poco") || q.contains("media hora")
        let isThisWeek   = q.contains("esta semana") || q.contains("últimos días")
        let isThisMonth  = q.contains("este mes")

        var periodLabel: String?
        var filtered: [TranscriptionRecord] = []

        if isYesterday {
            let yesterday = cal.date(byAdding: .day, value: -1, to: now)!
            filtered = records.filter { cal.isDate($0.timestamp, inSameDayAs: yesterday) }
            periodLabel = "Ayer"
        } else if isToday {
            filtered = records.filter { cal.isDateInToday($0.timestamp) }
            periodLabel = "Hoy"
        } else if isLastHour {
            let cutoff = cal.date(byAdding: .hour, value: -1, to: now)!
            filtered = records.filter { $0.timestamp >= cutoff }
            periodLabel = "En la última hora"
        } else if isThisWeek {
            let cutoff = cal.date(byAdding: .day, value: -7, to: now)!
            filtered = records.filter { $0.timestamp >= cutoff }
            periodLabel = "Esta semana"
        } else if isThisMonth {
            let cutoff = cal.date(byAdding: .month, value: -1, to: now)!
            filtered = records.filter { $0.timestamp >= cutoff }
            periodLabel = "Este mes"
        }

        let useRecords: [TranscriptionRecord]
        let header: String

        if let label = periodLabel {
            if filtered.isEmpty {
                useRecords = records
                header = "No encontré notas de \(label.lowercased()). Aquí están las más relevantes:"
            } else {
                useRecords = filtered
                let n = filtered.count
                header = "\(label) grabaste \(n) nota\(n == 1 ? "" : "s"):"
            }
        } else {
            useRecords = records
            let n = records.count
            header = "Encontré \(n) nota\(n == 1 ? "" : "s") relacionada\(n == 1 ? "" : "s"):"
        }

        var lines = [header, ""]
        for record in useRecords.prefix(5) {
            let dateStr = record.timestamp.formatted(.dateTime.day().month(.abbreviated).hour().minute())
            let dur = formatDuration(record.durationSeconds)
            let preview = String(record.text.prefix(160))
            let ellipsis = record.text.count > 160 ? "…" : ""
            lines.append("• **\(dateStr)** (\(dur))\n  \(preview)\(ellipsis)")
        }
        return lines.joined(separator: "\n")
    }

    private func formatDuration(_ seconds: Double) -> String {
        let s = Int(seconds)
        guard s > 0 else { return "—" }
        if s < 60 { return "\(s)s" }
        return "\(s / 60)m \(s % 60)s"
    }
}
