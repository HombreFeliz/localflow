import SwiftUI

struct ModelDownloadView: View {
    @ObservedObject var modelManager: ModelManager
    var onRetry: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform.and.mic")
                .font(.system(size: 48))
                .foregroundColor(.blue)
                .symbolEffect(.pulse, isActive: modelManager.downloadProgress > 0 && modelManager.downloadProgress < 1)

            Text("LocalFlow")
                .font(.system(size: 22, weight: .semibold))

            if let error = modelManager.errorMessage {
                VStack(spacing: 12) {
                    Text("Error al descargar el modelo")
                        .font(.headline)
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Reintentar") {
                        onRetry?()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                VStack(spacing: 10) {
                    Text("Descargando modelo Whisper Medium")
                        .font(.headline)
                    Text("~1.5 GB · Solo ocurre una vez")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ProgressView(value: modelManager.downloadProgress)
                        .progressViewStyle(.linear)
                        .frame(width: 280)

                    Text("\(Int(modelManager.downloadProgress * 100))%")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(32)
        .frame(width: 380, height: 280)
    }
}
