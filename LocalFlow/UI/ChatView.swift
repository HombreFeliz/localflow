import SwiftUI

// MARK: - ViewModel

@MainActor
@Observable
final class ChatViewModel {
    var messages: [ChatMessage] = []
    var inputText: String = ""
    var isLoading: Bool = false
    var errorMessage: String? = nil

    private let engine: LocalChatEngine

    init(historyStore: HistoryStore) {
        self.engine = LocalChatEngine(historyStore: historyStore)
    }

    func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }

        inputText = ""
        messages.append(ChatMessage(role: .user, content: text))
        let assistantIndex = messages.count
        messages.append(ChatMessage(role: .assistant, content: ""))
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let response = try await engine.respond(to: text)
                messages[assistantIndex].content = response
            } catch {
                messages[assistantIndex].content = ""
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func clearChat() {
        messages = []
        errorMessage = nil
        Task { await engine.clearHistory() }
    }
}

// MARK: - ChatView

struct ChatView: View {
    @State private var vm: ChatViewModel
    @AppStorage("com.localflow.accentColorName") private var accentColorName: String = "red"
    private var accentColor: Color { AccentColorOption(rawValue: accentColorName)?.color ?? .red }
    private var accentTextColor: Color { AccentColorOption(rawValue: accentColorName)?.textColor ?? .white }

    init(historyStore: HistoryStore) {
        _vm = State(initialValue: ChatViewModel(historyStore: historyStore))
    }

    var body: some View {
        VStack(spacing: 0) {
            messageArea
            Divider()
            inputBar
        }
    }

    // MARK: - Message area

    private var messageArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if vm.messages.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(vm.messages) { msg in
                            MessageRow(
                                message: msg,
                                accentColor: accentColor,
                                accentTextColor: accentTextColor
                            )
                            .id(msg.id)
                        }
                        if let err = vm.errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundStyle(.orange)
                                Text(err)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                        }
                        // Anchor for auto-scroll
                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding(.vertical, 8)
                }
            }
            .onChange(of: vm.messages.count) { _, _ in
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onChange(of: vm.messages.last?.content) { _, _ in
                proxy.scrollTo("bottom", anchor: .bottom)
            }
            .overlay(alignment: .topTrailing) {
                if !vm.messages.isEmpty {
                    Button {
                        withAnimation(.easeOut(duration: 0.15)) {
                            vm.clearChat()
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(7)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Nueva conversación")
                    .padding(10)
                }
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 44))
                .foregroundStyle(accentColor)
            Text("Pregúntame sobre tus notas")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            Text("Tengo acceso a todas tus transcripciones.\nPuedo ayudarte a recordar lo que dijiste.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: 8) {
                suggestionChip("¿Qué dije ayer?", accentColor: accentColor, accentTextColor: accentTextColor) {
                    vm.inputText = "¿Qué dije ayer?"
                }
                suggestionChip("Resume mis notas de esta semana", accentColor: accentColor, accentTextColor: accentTextColor) {
                    vm.inputText = "Resume mis notas de esta semana"
                }
                suggestionChip("¿Qué tareas he mencionado?", accentColor: accentColor, accentTextColor: accentTextColor) {
                    vm.inputText = "¿Qué tareas he mencionado?"
                }
            }
            .padding(.top, 4)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func suggestionChip(_ text: String, accentColor: Color, accentTextColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 12))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(accentColor.opacity(0.12))
                .foregroundStyle(accentColor)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(accentColor.opacity(0.25), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Input bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Escribe un mensaje...", text: $vm.inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .lineLimit(1...5)
                .onSubmit {
                    if !vm.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        vm.send()
                    }
                }

            Button {
                vm.send()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(
                        vm.inputText.trimmingCharacters(in: .whitespaces).isEmpty || vm.isLoading
                        ? AnyShapeStyle(Color.secondary.opacity(0.4))
                        : AnyShapeStyle(accentColor)
                    )
            }
            .buttonStyle(.plain)
            .disabled(vm.inputText.trimmingCharacters(in: .whitespaces).isEmpty || vm.isLoading)
            .keyboardShortcut(.return, modifiers: .command)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.windowBackground)
    }
}

// MARK: - Message row

struct MessageRow: View {
    let message: ChatMessage
    let accentColor: Color
    let accentTextColor: Color

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if message.role == .user {
                Spacer(minLength: 72)
                userBubble
                    .padding(.trailing, 16)
                    .padding(.vertical, 4)
            } else {
                assistantBubble
                    .padding(.leading, 16)
                    .padding(.vertical, 4)
                Spacer(minLength: 72)
            }
        }
    }

    // User bubble — right, accent color
    private var userBubble: some View {
        Text(message.content)
            .font(.system(size: 13))
            .foregroundStyle(accentTextColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(accentColor)
            .clipShape(BubbleShape(role: .user))
    }

    // Assistant bubble — left, material + robot icon
    private var assistantBubble: some View {
        HStack(alignment: .top, spacing: 8) {
            // Bot avatar
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 28, height: 28)
                Image(systemName: "sparkle")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(accentColor)
            }

            Group {
                if message.content.isEmpty {
                    LoadingDots(color: accentColor)
                        .frame(height: 20)
                } else {
                    Group {
                        if let md = try? AttributedString(
                            markdown: message.content,
                            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
                        ) {
                            Text(md).textSelection(.enabled)
                        } else {
                            Text(message.content).textSelection(.enabled)
                        }
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(.ultraThinMaterial)
            .clipShape(BubbleShape(role: .assistant))
        }
    }
}

// MARK: - Bubble shape (rounded, flat corner on sender side)

struct BubbleShape: Shape {
    let role: ChatMessage.Role
    private let r: CGFloat = 16
    private let rSmall: CGFloat = 5

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let tl = role == .user ? r : rSmall  // top-left corner
        let tr = role == .user ? rSmall : r  // top-right corner
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: r, height: r))
        // Override specific corners for messenger-style
        _ = tl; _ = tr  // used conceptually; simple version below
        return Path(roundedRect: rect, cornerRadius: r)
    }
}

// MARK: - Loading dots animation

struct LoadingDots: View {
    let color: Color
    @State private var phase = 0

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(color.opacity(phase == i ? 1.0 : 0.35))
                    .frame(width: 7, height: 7)
                    .scaleEffect(phase == i ? 1.15 : 0.9)
                    .animation(.easeInOut(duration: 0.4).repeatForever().delay(Double(i) * 0.15), value: phase)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                phase = (phase + 1) % 3
            }
        }
    }
}
