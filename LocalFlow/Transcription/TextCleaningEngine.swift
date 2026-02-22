import Foundation

actor TextCleaningEngine {
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 10
        session = URLSession(configuration: config)
    }

    func isOllamaAvailable(host: String) async -> Bool {
        guard let url = URL(string: "\(host)/api/tags") else { return false }
        do {
            let (_, response) = try await session.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    func clean(text: String, language: String, model: String, host: String) async -> String {
        guard let url = URL(string: "\(host)/api/generate") else { return text }

        let systemPrompt = """
        You are a transcript cleanup assistant. Given raw speech-to-text output, return ONLY the cleaned text with no explanations or commentary. Apply these fixes:
        - Remove filler words and verbal tics (um, uh, eh, hmm, o sea, bueno, pues, a ver, este, mhm...)
        - Remove stutters and word repetitions (if a word or phrase appears twice in a row, keep it once)
        - Add proper punctuation and capitalization
        - Fix obvious speech recognition errors using context
        - If the speaker enumerates items or a list, format them as a numbered list or bullet points on separate lines
        - Preserve the original language exactly — do not translate
        - Do not add, invent, or remove meaningful content
        """

        let userPrompt = "Clean this transcript:\n\n\(text)"
        let fullPrompt = "<system>\n\(systemPrompt)\n</system>\n\n\(userPrompt)"

        let body: [String: Any] = [
            "model": model,
            "prompt": fullPrompt,
            "stream": false,
            "options": [
                "temperature": 0.1,
                "num_predict": 1024
            ]
        ]

        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else { return text }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        do {
            let (data, response) = try await session.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return text }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let cleaned = json?["response"] as? String ?? text
            return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return text
        }
    }
}
