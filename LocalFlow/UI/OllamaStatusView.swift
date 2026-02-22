import SwiftUI

struct OllamaStatusView: View {
    let host: String
    @State private var status: OllamaStatus = .checking

    enum OllamaStatus {
        case checking, available, unavailable
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(dotColor)
                .frame(width: 8, height: 8)
            Text(statusText)
                .font(.caption)
                .foregroundStyle(labelColor)
            Spacer()
            Button("Verificar") {
                Task { await checkStatus() }
            }
            .font(.caption)
            .buttonStyle(.borderless)
        }
        .task { await checkStatus() }
        .onChange(of: host) { _, _ in
            Task { await checkStatus() }
        }
    }

    private var dotColor: Color {
        switch status {
        case .checking: return .gray
        case .available: return .green
        case .unavailable: return .red
        }
    }

    private var labelColor: Color {
        switch status {
        case .checking: return .secondary
        case .available: return .primary
        case .unavailable: return .secondary
        }
    }

    private var statusText: String {
        switch status {
        case .checking: return "Comprobando Ollama..."
        case .available: return "Ollama disponible"
        case .unavailable: return "Ollama no detectado"
        }
    }

    private func checkStatus() async {
        status = .checking
        let engine = TextCleaningEngine()
        let available = await engine.isOllamaAvailable(host: host)
        status = available ? .available : .unavailable
    }
}
