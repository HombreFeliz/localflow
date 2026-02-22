import WhisperKit
import Foundation

@MainActor
final class ModelManager: ObservableObject {
    @Published var downloadProgress: Double = 0.0
    @Published var isReady: Bool = false
    @Published var errorMessage: String?

    static let modelVariant = "openai_whisper-medium"

    private(set) var modelFolder: URL?

    nonisolated init() {}

    func ensureModelReady() async {
        if let existing = findLocalModel() {
            modelFolder = existing
            isReady = true
            return
        }
        await downloadModel()
    }

    func downloadModel() async {
        downloadProgress = 0
        errorMessage = nil

        do {
            let folder = try await WhisperKit.download(
                variant: Self.modelVariant,
                progressCallback: { progress in
                    Task { @MainActor in
                        self.downloadProgress = progress.fractionCompleted
                    }
                }
            )
            modelFolder = folder
            downloadProgress = 1.0
            isReady = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func findLocalModel() -> URL? {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else { return nil }

        let modelPath = appSupport
            .appendingPathComponent("huggingface")
            .appendingPathComponent("models")
            .appendingPathComponent("argmaxinc")
            .appendingPathComponent("whisperkit-coreml")
            .appendingPathComponent(Self.modelVariant)

        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: modelPath.path, isDirectory: &isDir)
        return (exists && isDir.boolValue) ? modelPath : nil
    }
}
