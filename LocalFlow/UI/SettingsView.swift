import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsStore
    @ObservedObject var modelManager: ModelManager
    @State private var newBundleID: String = ""

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

            Section("Captura de texto (apps)") {
                Toggle("Activar captura de texto de apps", isOn: $settings.enableAppCapture)
                    .onChange(of: settings.enableAppCapture) { _, _ in
                        NotificationCenter.default.post(name: .settingsChanged, object: nil)
                    }

                if settings.enableAppCapture {
                    Text("Lee el contenido de apps monitorizadas para dar contexto completo al chat.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !settings.monitoredBundleIDs.isEmpty {
                        ForEach(settings.monitoredBundleIDs, id: \.self) { bundleID in
                            HStack {
                                Text(bundleID)
                                    .font(.system(size: 12, design: .monospaced))
                                Spacer()
                                Button {
                                    settings.monitoredBundleIDs.removeAll { $0 == bundleID }
                                    NotificationCenter.default.post(name: .settingsChanged, object: nil)
                                } label: {
                                    Image(systemName: "minus.circle")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }

                    HStack {
                        TextField("com.example.app", text: $newBundleID)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12, design: .monospaced))
                        Button("Agregar") {
                            let trimmed = newBundleID.trimmingCharacters(in: .whitespaces)
                            guard !trimmed.isEmpty, !settings.monitoredBundleIDs.contains(trimmed) else { return }
                            settings.monitoredBundleIDs.append(trimmed)
                            newBundleID = ""
                            NotificationCenter.default.post(name: .settingsChanged, object: nil)
                        }
                        .disabled(newBundleID.trimmingCharacters(in: .whitespaces).isEmpty)
                    }

                    if !settings.monitoredBundleIDs.contains("com.anthropic.claudefordesktop") {
                        Button("Agregar Claude Desktop") {
                            settings.monitoredBundleIDs.append("com.anthropic.claudefordesktop")
                            NotificationCenter.default.post(name: .settingsChanged, object: nil)
                        }
                        .font(.caption)
                    }
                }
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
        .frame(width: 420, height: 460)
        .navigationTitle("LocalFlow")
    }
}

extension Notification.Name {
    static let settingsChanged = Notification.Name("com.localflow.settingsChanged")
}
