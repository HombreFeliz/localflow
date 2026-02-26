import SwiftUI

struct MainView: View {
    let historyStore: HistoryStore
    @State private var expandedID: UUID? = nil

    var body: some View {
        VStack(spacing: 0) {
            StatsBarView(historyStore: historyStore)
            Divider()

            if historyStore.records.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0, pinnedViews: .sectionHeaders) {
                        ForEach(groupedRecords, id: \.key) { group in
                            Section {
                                ForEach(group.records) { record in
                                    TranscriptionRowView(
                                        record: record,
                                        isExpanded: expandedID == record.id,
                                        onTap: {
                                            withAnimation(.easeInOut(duration: 0.15)) {
                                                expandedID = expandedID == record.id ? nil : record.id
                                            }
                                        },
                                        onDelete: { historyStore.delete(id: record.id) }
                                    )
                                    Divider().padding(.leading, 56)
                                }
                            } header: {
                                Text(group.key)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 16)
                                    .padding(.bottom, 6)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(.windowBackground)
                            }
                        }
                    }
                    .padding(.bottom, 16)
                }
            }
        }
        .frame(minWidth: 560, minHeight: 400)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.and.mic")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text("Sin transcripciones todavía")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Mantén pulsada la tecla Globe y empieza a hablar.")
                .font(.callout)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Grouping

    private struct DayGroup {
        let key: String
        let records: [TranscriptionRecord]
    }

    private var groupedRecords: [DayGroup] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let grouped = Dictionary(grouping: historyStore.records) { record in
            calendar.startOfDay(for: record.timestamp)
        }

        return grouped.keys.sorted(by: >).map { day in
            let label: String
            if day == today {
                label = "Hoy"
            } else if day == yesterday {
                label = "Ayer"
            } else {
                label = day.formatted(.dateTime.weekday(.wide).day().month(.wide))
            }
            return DayGroup(key: label, records: grouped[day]!.sorted { $0.timestamp > $1.timestamp })
        }
    }
}

// MARK: - Row

struct TranscriptionRowView: View {
    let record: TranscriptionRecord
    let isExpanded: Bool
    let onTap: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // Hora
                Text(record.timestamp.formatted(.dateTime.hour().minute()))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, alignment: .trailing)

                // Texto
                VStack(alignment: .leading, spacing: 4) {
                    Text(isExpanded ? record.text : record.text.truncated(to: 120))
                        .font(.system(size: 13))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .animation(.none, value: isExpanded)

                    HStack(spacing: 6) {
                        Text("\(record.wordCount) palabras")
                        Text("·")
                        Text(displayLanguage)
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                }

                Spacer()

                // Acciones (visibles en hover o expandido)
                if isHovering || isExpanded {
                    HStack(spacing: 4) {
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(record.text, forType: .string)
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                        .buttonStyle(.borderless)
                        .help("Copiar")

                        Button(role: .destructive, action: onDelete) {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(.red.opacity(0.7))
                        .help("Eliminar")
                    }
                    .font(.system(size: 13))
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
            .onHover { isHovering = $0 }
            .background(isHovering ? Color.primary.opacity(0.04) : .clear)
        }
    }

    private var displayLanguage: String {
        switch record.language {
        case "es": return "Español"
        case "en": return "English"
        case "ca": return "Català"
        case "fr": return "Français"
        case "de": return "Deutsch"
        case "pt": return "Português"
        case "it": return "Italiano"
        case "ja": return "日本語"
        case "zh": return "中文"
        case "auto": return "Auto"
        default: return record.language
        }
    }
}

private extension String {
    func truncated(to length: Int) -> String {
        guard count > length else { return self }
        return String(prefix(length)) + "…"
    }
}
