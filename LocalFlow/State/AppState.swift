import Foundation

let appVersion = "v3.7"

enum AppStatus: Equatable {
    case downloadingModel(progress: Double)
    case modelReady
    case idle
    case recording
    case paused
    case transcribing
    case error(String)

    static func == (lhs: AppStatus, rhs: AppStatus) -> Bool {
        switch (lhs, rhs) {
        case (.downloadingModel(let a), .downloadingModel(let b)): return a == b
        case (.modelReady, .modelReady): return true
        case (.idle, .idle): return true
        case (.recording, .recording): return true
        case (.paused, .paused): return true
        case (.transcribing, .transcribing): return true
        case (.error(let a), .error(let b)): return a == b
        default: return false
        }
    }
}

@MainActor
@Observable
final class AppState {
    nonisolated init() {}

    var status: AppStatus = .idle
    var waveformAmplitudes: [Float] = Array(repeating: 0.05, count: 40)
    var lastTranscription: String = ""
    var isRecording: Bool = false
    var transcriptionEstimatedDuration: Double = 0
    var isEmbeddingInBackground: Bool = false
    var embeddedRecordCount: Int = 0
    var totalRecordsToEmbed: Int = 0

    // Callbacks para que la UI pueda controlar la grabación sin conocer AppDelegate
    var onPauseRecording: (() -> Void)?
    var onResumeRecording: (() -> Void)?
    var onStopRecording: (() -> Void)?

    var isReadyToRecord: Bool {
        if case .idle = status { return true }
        return false
    }

    var downloadProgress: Double {
        if case .downloadingModel(let p) = status { return p }
        return 0
    }

    var isDownloading: Bool {
        if case .downloadingModel = status { return true }
        return false
    }
}
