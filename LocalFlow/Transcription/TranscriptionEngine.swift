import WhisperKit
import Foundation

actor TranscriptionEngine {
    private var pipe: WhisperKit?
    private(set) var isLoaded: Bool = false

    func load(modelFolder: URL) async throws {
        let config = WhisperKitConfig(
            modelFolder: modelFolder.path,
            verbose: false,
            logLevel: .error,
            prewarm: true,
            load: true,
            download: false
        )
        pipe = try await WhisperKit(config)
        isLoaded = true
    }

    func transcribe(audioSamples: [Float], language: String) async throws -> String {
        guard let pipe = pipe else {
            throw TranscriptionError.notLoaded
        }

        let isAuto = language == "auto"
        let options = DecodingOptions(
            verbose: false,
            task: .transcribe,
            language: isAuto ? nil : language,
            detectLanguage: isAuto,
            skipSpecialTokens: true,
            withoutTimestamps: true,
            noSpeechThreshold: 0.3
        )

        let results: [TranscriptionResult] = try await pipe.transcribe(
            audioArray: audioSamples,
            decodeOptions: options
        )
        let text = results.map { $0.text }.joined(separator: " ")
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum TranscriptionError: Error, LocalizedError {
    case notLoaded

    var errorDescription: String? {
        "El modelo de transcripción no está cargado."
    }
}
