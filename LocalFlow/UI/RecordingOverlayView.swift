import SwiftUI

struct RecordingOverlayView: View {
    @Environment(AppState.self) var appState
    @AppStorage("com.localflow.accentColorName") private var accentColorName: String = "red"
    @State private var arcProgress: Double = 0

    private var accentColor: Color { AccentColorOption(rawValue: accentColorName)?.color ?? .red }
    private var accentTextColor: Color { AccentColorOption(rawValue: accentColorName)?.textColor ?? .white }

    private var isTranscribing: Bool {
        if case .transcribing = appState.status { return true }
        return false
    }

    var body: some View {
        ZStack {
            if isTranscribing {
                transcribingCircle
            } else {
                pillContent
            }
        }
        .frame(width: isTranscribing ? 52 : 160, height: 52)
        .clipShape(isTranscribing ? AnyShape(Circle()) : AnyShape(Capsule()))
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isTranscribing)
        .onChange(of: isTranscribing) { _, newValue in
            if newValue {
                arcProgress = 0
                withAnimation(.linear(duration: appState.transcriptionEstimatedDuration)) {
                    arcProgress = 0.92
                }
            } else {
                arcProgress = 0
            }
        }
    }

    // MARK: - Transcribing circle

    private var transcribingCircle: some View {
        ZStack {
            Circle()
                .fill(accentColor)

            Circle()
                .trim(from: 0, to: arcProgress)
                .stroke(
                    accentTextColor,
                    style: StrokeStyle(lineWidth: 4.5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            ProgressView()
                .scaleEffect(0.65)
                .tint(accentTextColor)
        }
    }

    // MARK: - Pill content

    private var pillContent: some View {
        ZStack {
            Capsule()
                .fill(accentColor)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 3)

            waveformOrPauseView
                .padding(.horizontal, 16)
        }
        .clipShape(Capsule())
    }

    // MARK: - Waveform / pause state

    @ViewBuilder
    private var waveformOrPauseView: some View {
        if isPaused {
            HStack(spacing: 5) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.orange)
                Text("Pausado")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        } else {
            HStack(spacing: 2) {
                ForEach(Array(appState.waveformAmplitudes.prefix(12).enumerated()), id: \.offset) { index, amp in
                    Capsule()
                        .fill(barColor)
                        .frame(width: 2.5, height: barHeight(amp))
                        .animation(
                            .easeOut(duration: 0.08).delay(Double(index) * 0.002),
                            value: amp
                        )
                }
            }
        }
    }

    // MARK: - Buttons

    private var pauseButton: some View {
        Button {
            if case .paused = appState.status {
                appState.onResumeRecording?()
            } else {
                appState.onPauseRecording?()
            }
        } label: {
            Image(systemName: isPaused ? "play.fill" : "pause.fill")
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 28, height: 28)
                .background(Color.primary.opacity(0.1))
                .clipShape(Circle())
                .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
    }

    private var stopButton: some View {
        Button {
            appState.onStopRecording?()
        } label: {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .bold))
                .frame(width: 28, height: 28)
                .background(Color.red.opacity(0.85))
                .clipShape(Circle())
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var isPaused: Bool {
        if case .paused = appState.status { return true }
        return false
    }

    private func barHeight(_ amplitude: Float) -> CGFloat {
        let minH: CGFloat = 3
        let maxH: CGFloat = 34
        return minH + CGFloat(amplitude).squareRoot() * (maxH - minH)
    }

    private var barColor: Color { accentTextColor }
}
