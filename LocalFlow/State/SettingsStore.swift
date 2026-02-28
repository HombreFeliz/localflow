import SwiftUI

enum AccentColorOption: String, CaseIterable, Identifiable {
    case red, blue, orange, purple, green, teal
    var id: String { rawValue }
    var color: Color {
        switch self {
        case .red: return .red
        case .blue: return .blue
        case .orange: return .orange
        case .purple: return .purple
        case .green: return .green
        case .teal: return .teal
        }
    }
    // Colores claros necesitan texto oscuro para mantener contraste WCAG
    var textColor: Color {
        switch self {
        case .orange, .green, .teal: return Color.black.opacity(0.75)
        default: return .white
        }
    }
}

@MainActor
final class SettingsStore: ObservableObject {
    nonisolated init() {}

    @AppStorage("com.localflow.language") var language: String = "auto"
    @AppStorage("com.localflow.recordingMode") var recordingMode: String = "holdToTalk"
    @AppStorage("com.localflow.modelDownloaded") var modelDownloaded: Bool = false
    @AppStorage("com.localflow.hotKeyUsesGlobe") var hotKeyUsesGlobe: Bool = true
    @AppStorage("com.localflow.useClipboardFallback") var useClipboardFallback: Bool = false
    @AppStorage("com.localflow.hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    @AppStorage("com.localflow.accentColorName") var accentColorName: String = "red"
    var accentColor: Color { AccentColorOption(rawValue: accentColorName)?.color ?? .red }
    var accentTextColor: Color { AccentColorOption(rawValue: accentColorName)?.textColor ?? .white }

    @AppStorage("com.localflow.enableAppCapture") var enableAppCapture: Bool = false
    @AppStorage("com.localflow.monitoredBundleIDs") var monitoredBundleIDsRaw: String = ""
    @AppStorage("com.localflow.capturePollingInterval") var capturePollingInterval: Double = 4.0

    var monitoredBundleIDs: [String] {
        get { monitoredBundleIDsRaw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } }
        set { monitoredBundleIDsRaw = newValue.joined(separator: ",") }
    }
}
