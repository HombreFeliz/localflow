import SwiftUI

struct StatsBarView: View {
    let historyStore: HistoryStore

    var body: some View {
        HStack(spacing: 0) {
            statPill(icon: "flame.fill", color: .orange, value: "\(historyStore.streakDays)", label: streakLabel)
            Divider().frame(height: 20).padding(.horizontal, 16)
            statPill(icon: "text.word.spacing", color: .blue, value: formattedWords, label: "palabras")
            Divider().frame(height: 20).padding(.horizontal, 16)
            statPill(icon: "bolt.fill", color: .yellow, value: "\(historyStore.averageWPM)", label: "ppm")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(.bar)
    }

    private func statPill(icon: String, color: Color, value: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.system(size: 13, weight: .semibold))
            Text(value)
                .font(.system(size: 15, weight: .semibold))
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
    }

    private var formattedWords: String {
        let n = historyStore.totalWords
        if n >= 1000 { return String(format: "%.1fk", Double(n) / 1000) }
        return "\(n)"
    }

    private var streakLabel: String {
        historyStore.streakDays == 1 ? "día" : "días"
    }
}
