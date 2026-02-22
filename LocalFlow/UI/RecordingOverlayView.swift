import SwiftUI

struct RecordingOverlayView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 4)

            if case .transcribing = appState.status {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.secondary)
                    Text("Transcribiendo...")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            } else if case .cleaning = appState.status {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13))
                        .foregroundStyle(.orange)
                        .symbolEffect(.pulse)
                    Text("Puliendo texto...")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack(spacing: 3) {
                    ForEach(Array(appState.waveformAmplitudes.enumerated()), id: \.offset) { index, amp in
                        Capsule()
                            .fill(barColor)
                            .frame(width: 3, height: barHeight(amp))
                            .animation(
                                .easeOut(duration: 0.08).delay(Double(index) * 0.002),
                                value: amp
                            )
                    }
                }
                .padding(.horizontal, 14)
            }
        }
        .frame(width: 220, height: 60)
    }

    private func barHeight(_ amplitude: Float) -> CGFloat {
        let minH: CGFloat = 3
        let maxH: CGFloat = 42
        return minH + CGFloat(amplitude) * (maxH - minH)
    }

    private var barColor: Color {
        switch appState.status {
        case .recording: return .red.opacity(0.85)
        case .transcribing: return .orange
        default: return .accentColor
        }
    }
}
