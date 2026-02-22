import SwiftUI

@MainActor
final class SettingsStore: ObservableObject {
    nonisolated init() {}

    @AppStorage("com.localflow.language") var language: String = "auto"
    @AppStorage("com.localflow.recordingMode") var recordingMode: String = "holdToTalk"
    @AppStorage("com.localflow.modelDownloaded") var modelDownloaded: Bool = false
    @AppStorage("com.localflow.hotKeyUsesGlobe") var hotKeyUsesGlobe: Bool = true
    @AppStorage("com.localflow.useClipboardFallback") var useClipboardFallback: Bool = false
    @AppStorage("com.localflow.cleaningEnabled") var cleaningEnabled: Bool = false
    @AppStorage("com.localflow.ollamaModel") var ollamaModel: String = "llama3.2:1b"
    @AppStorage("com.localflow.ollamaHost") var ollamaHost: String = "http://127.0.0.1:11434"
}
