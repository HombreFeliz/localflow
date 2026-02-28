import SwiftUI

struct MainView: View {
    let historyStore: HistoryStore
    let settingsStore: SettingsStore
    let appState: AppState
    @State private var selectedApp: String? = nil
    @State private var showOnboardingHelp = false
    @State private var showChat = false

    var body: some View {
        Group {
            if showChat {
                ChatView(historyStore: historyStore)
            } else {
                historyContent
            }
        }
        .frame(minWidth: 560, minHeight: 400)
        .toolbar {
            if appState.isEmbeddingInBackground {
                ToolbarItem(placement: .automatic) {
                    HStack(spacing: 4) {
                        ProgressView().scaleEffect(0.6)
                        if appState.totalRecordsToEmbed > 0 {
                            Text("\(appState.embeddedRecordCount)/\(appState.totalRecordsToEmbed)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .help("Indexando transcripciones para búsqueda semántica...")
                }
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showChat.toggle() }
                } label: {
                    Image(systemName: showChat ? "clock" : "bubble.left.and.bubble.right")
                }
                .help(showChat ? "Ver historial" : "Chat con tus notas")
            }
            ToolbarItem(placement: .automatic) {
                ColorPickerPopover()
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    showOnboardingHelp = true
                } label: {
                    Image(systemName: "questionmark.circle")
                }
                .help("Ayuda")
            }
        }
        .sheet(isPresented: $showOnboardingHelp) {
            OnboardingView(settingsStore: settingsStore, onDismiss: { showOnboardingHelp = false })
        }
    }

    // MARK: - History content

    private var historyContent: some View {
        VStack(spacing: 0) {
            StatsBarView(historyStore: historyStore)
            Divider()

            if uniqueApps.count >= 2 {
                AppFilterBar(apps: uniqueApps, selectedApp: $selectedApp)
                Divider()
            }

            if filteredRecords.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0, pinnedViews: .sectionHeaders) {
                        ForEach(groupedRecords, id: \.key) { group in
                            Section {
                                ForEach(group.records) { record in
                                    TranscriptionRowView(
                                        record: record,
                                        onDelete: { historyStore.delete(id: record.id) },
                                        onTapApp: { app in
                                            withAnimation(.easeInOut(duration: 0.15)) {
                                                selectedApp = app
                                            }
                                        }
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
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: selectedApp != nil ? "line.3.horizontal.decrease.circle" : "waveform.and.mic")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text(selectedApp != nil ? "Sin transcripciones en \(selectedApp!)" : "Sin transcripciones todavía")
                .font(.title3)
                .foregroundStyle(.secondary)
            if selectedApp != nil {
                Button("Ver todas") {
                    withAnimation(.easeInOut(duration: 0.15)) { selectedApp = nil }
                }
                .buttonStyle(.borderless)
                .foregroundStyle(Color.accentColor)
            } else {
                Text("Mantén pulsada la tecla Globe y empieza a hablar.")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Filtering & Grouping

    private var uniqueApps: [String] {
        let apps = historyStore.records.compactMap(\.targetApp)
        return Array(Set(apps)).sorted()
    }

    private var filteredRecords: [TranscriptionRecord] {
        var records = historyStore.records
        if let app = selectedApp {
            records = records.filter { $0.targetApp == app }
        }
        return records
    }

    private struct DayGroup {
        let key: String
        let records: [TranscriptionRecord]
    }

    private var groupedRecords: [DayGroup] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let grouped = Dictionary(grouping: filteredRecords) { record in
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

// MARK: - Filter Bar

struct AppFilterBar: View {
    let apps: [String]
    @Binding var selectedApp: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "Todas", isSelected: selectedApp == nil) {
                    withAnimation(.easeInOut(duration: 0.15)) { selectedApp = nil }
                }
                ForEach(apps, id: \.self) { app in
                    FilterChip(label: app, isSelected: selectedApp == app) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedApp = selectedApp == app ? nil : app
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    @AppStorage("com.localflow.accentColorName") private var accentColorName: String = "red"
    private var accentColor: Color { AccentColorOption(rawValue: accentColorName)?.color ?? .red }
    private var accentTextColor: Color { AccentColorOption(rawValue: accentColorName)?.textColor ?? .white }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(isSelected ? accentColor : Color.primary.opacity(0.08))
                .foregroundStyle(isSelected ? accentTextColor : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Color Picker Popover

struct ColorPickerPopover: View {
    @AppStorage("com.localflow.accentColorName") private var accentColorName: String = "red"
    @State private var showPopover = false
    private var current: Color { AccentColorOption(rawValue: accentColorName)?.color ?? .red }

    var body: some View {
        Button { showPopover = true } label: {
            Circle().fill(current).frame(width: 14, height: 14)
        }
        .buttonStyle(.plain)
        .help("Color de la interfaz")
        .popover(isPresented: $showPopover) {
            HStack(spacing: 10) {
                ForEach(AccentColorOption.allCases) { option in
                    Button { accentColorName = option.rawValue } label: {
                        ZStack {
                            Circle().fill(option.color).frame(width: 28, height: 28)
                            if accentColorName == option.rawValue {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(option.textColor)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
        }
    }
}

// MARK: - Row

struct TranscriptionRowView: View {
    let record: TranscriptionRecord
    let onDelete: () -> Void
    var onTapApp: ((String) -> Void)? = nil

    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Text(record.timestamp.formatted(.dateTime.hour().minute()))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, alignment: .trailing)

                VStack(alignment: .leading, spacing: 4) {
                    Text(record.text)
                        .font(.system(size: 13))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 6) {
                        if record.source == .appCapture {
                            Image(systemName: "eye")
                                .font(.system(size: 10))
                                .foregroundStyle(.blue)
                            Text("·")
                        }
                        Text("\(record.wordCount) palabras")
                        Text("·")
                        Text(displayLanguage)
                        if let app = record.targetApp {
                            Text("·")
                            Button {
                                onTapApp?(app)
                            } label: {
                                Text(app)
                                    .underline(isHovering)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                }

                Spacer()

                if isHovering {
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
