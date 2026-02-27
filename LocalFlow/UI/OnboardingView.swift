import SwiftUI

struct OnboardingView: View {
    let settingsStore: SettingsStore
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Icon + title
            VStack(spacing: 10) {
                Image(systemName: "waveform.and.mic")
                    .font(.system(size: 40))
                    .foregroundStyle(settingsStore.accentColor)
                    .padding(.top, 48)

                Text("Bienvenido a LocalFlow")
                    .font(.title2)
                    .fontWeight(.semibold)
            }

            // Steps
            VStack(alignment: .leading, spacing: 16) {
                onboardingStep(
                    number: "1",
                    title: "Mantén pulsado Globe",
                    detail: "Habla mientras sostienes la tecla Globe (Fn). Suelta para transcribir."
                )
                onboardingStep(
                    number: "2",
                    title: "El texto aparece donde está el cursor",
                    detail: "La transcripción se pega automáticamente en la app que tengas activa."
                )
                onboardingStep(
                    number: "3",
                    title: "Todo queda guardado",
                    detail: "Abre LocalFlow desde la barra de menú para ver tu historial de transcripciones."
                )
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)
            .padding(.bottom, 8)

            Spacer()

            // Dismiss button
            Button {
                settingsStore.hasSeenOnboarding = true
                onDismiss()
            } label: {
                Text("Entendido")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(settingsStore.accentColor)
                    .foregroundStyle(settingsStore.accentTextColor)
                    .clipShape(RoundedRectangle(cornerRadius: 9))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 28)
            .padding(.bottom, 12)

            Text("LocalFlow \(appVersion)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 28)
        }
        .frame(width: 360, height: 400)
    }

    private func onboardingStep(number: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(settingsStore.accentTextColor)
                .frame(width: 24, height: 24)
                .background(settingsStore.accentColor)
                .clipShape(Circle())
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
