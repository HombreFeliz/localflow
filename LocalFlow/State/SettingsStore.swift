import SwiftUI

@MainActor
final class SettingsStore: ObservableObject {
    nonisolated init() {}

    @AppStorage("com.localflow.language") var language: String = "auto"
    @AppStorage("com.localflow.recordingMode") var recordingMode: String = "holdToTalk"
    @AppStorage("com.localflow.modelDownloaded") var modelDownloaded: Bool = false
    @AppStorage("com.localflow.hotKeyUsesGlobe") var hotKeyUsesGlobe: Bool = true
    @AppStorage("com.localflow.useClipboardFallback") var useClipboardFallback: Bool = false
}
