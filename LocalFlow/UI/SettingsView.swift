import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsStore
    @ObservedObject var modelManager: ModelManager

    var body: some View {
        Form {
            Section("Transcripción") {
                Picker("Idioma", selection: $settings.language) {
                    Text("Detectar automáticamente").tag("auto")
                    Divider()
                    Text("Español").tag("es")
                    Text("English").tag("en")
                    Text("Català").tag("ca")
                    Text("Français").tag("fr")
                    Text("Deutsch").tag("de")
                    Text("Português").tag("pt")
                    Text("Italiano").tag("it")
                    Text("日本語").tag("ja")
                    Text("中文").tag("zh")
                }
                .pickerStyle(.menu)
            }

            Section("Inyección de texto") {
                Toggle("Usar portapapeles (compatible con todas las apps)", isOn: $settings.useClipboardFallback)
                Text("Activa esto si el texto no aparece en VS Code, Chrome u otras apps.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Modelo") {
                LabeledContent("Modelo", value: "Whisper Medium")
                LabeledContent("Tamaño", value: "~1.5 GB")
                LabeledContent("Estado") {
                    if settings.modelDownloaded {
                        Label("Descargado", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Label("No descargado", systemImage: "xmark.circle")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 300)
        .navigationTitle("LocalFlow")
    }
}

extension Notification.Name {
    static let settingsChanged = Notification.Name("com.localflow.settingsChanged")
}
