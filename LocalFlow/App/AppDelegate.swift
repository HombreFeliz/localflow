import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    let settingsStore = SettingsStore()
    let historyStore = HistoryStore()

    private let audioRecorder = AudioRecorder()
    private let transcriptionEngine = TranscriptionEngine()
    let modelManager = ModelManager()
    private let hotKeyManager = HotKeyManager()
    private let textInjector = TextInjector()
    private let menuBarController = MenuBarController()

    private var textCaptureEngine: AppTextCaptureEngine?
    private var floatingPanel: FloatingPanel?
    private var downloadWindow: NSWindow?
    private var onboardingWindow: NSWindow?
    private var mainWindowController: MainWindowController?
    private var chatWindowController: ChatWindowController?
    private var recordingStartTime: Date = .now

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        historyStore.load()
        floatingPanel = FloatingPanel(appState: appState)

        menuBarController.setup(settingsStore: settingsStore, openMainWindow: { [weak self] in
            self?.openMainWindow()
        }, openChat: { [weak self] in
            self?.openChatWindow()
        })

        wireAudioToWaveform()
        wireRecordingCallbacks()
        wireHotKeys()

        if !settingsStore.hasSeenOnboarding {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.showOnboardingWindow()
            }
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onSettingsChanged),
            name: .settingsChanged,
            object: nil
        )

        Task { @MainActor in
            await startupModelCheck()
        }
    }

    // MARK: - Main Window

    func openMainWindow() {
        if mainWindowController == nil {
            mainWindowController = MainWindowController(
                historyStore: historyStore,
                settingsStore: settingsStore,
                appState: appState
            )
        }
        mainWindowController?.show()
    }

    func openChatWindow() {
        if chatWindowController == nil {
            chatWindowController = ChatWindowController(historyStore: historyStore)
        }
        chatWindowController?.show()
    }

    // MARK: - Onboarding

    private func showOnboardingWindow() {
        guard onboardingWindow == nil else { return }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 370),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "LocalFlow"
        window.isReleasedWhenClosed = false
        window.center()

        let view = OnboardingView(settingsStore: settingsStore) { [weak window, weak self] in
            window?.close()
            self?.onboardingWindow = nil
        }
        window.contentViewController = NSHostingController(rootView: view)

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        onboardingWindow = window
    }

    // MARK: - Model Loading

    @MainActor
    private func startupModelCheck() async {
        if settingsStore.modelDownloaded {
            // Model should already be on disk — use ensureModelReady() which handles
            // path resolution reliably (avoids findLocalModel() path mismatches)
            await modelManager.ensureModelReady()
            if let folder = modelManager.modelFolder {
                do {
                    try await transcriptionEngine.load(modelFolder: folder)
                    appState.status = .idle
                    requestPermissions()
                    if settingsStore.enableAppCapture { startTextCapture() }
                    let snapshot = historyStore.records
                    Task.detached(priority: .background) { [weak self] in
                        guard let self else { return }
                        await MainActor.run {
                            self.appState.isEmbeddingInBackground = true
                            self.appState.embeddedRecordCount = 0
                            self.appState.totalRecordsToEmbed = snapshot.count
                        }
                        var index: [UUID: [[Float]]] = [:]
                        for record in snapshot {
                            let chunks = EmbeddingEngine.chunkText(record.text)
                            var chunkVecs: [[Float]] = []
                            for chunk in chunks {
                                if let vec = await EmbeddingEngine.shared.embed(chunk, language: record.language) {
                                    chunkVecs.append(vec)
                                }
                            }
                            if !chunkVecs.isEmpty { index[record.id] = chunkVecs }
                            await MainActor.run { self.appState.embeddedRecordCount += 1 }
                        }
                        let builtIndex = index
                        await MainActor.run {
                            self.historyStore.updateSemanticIndex(builtIndex)
                            self.appState.isEmbeddingInBackground = false
                        }
                    }
                    return
                } catch {
                    // Model file corrupted or incompatible — fall through to re-download
                }
            }
            settingsStore.modelDownloaded = false
        }
        await triggerDownload()
    }

    @MainActor
    private func triggerDownload() async {
        // Only show the download window if the model doesn't exist locally yet
        if modelManager.findLocalModel() == nil { showDownloadWindow() }
        await modelManager.ensureModelReady()

        if let folder = modelManager.modelFolder {
            do {
                try await transcriptionEngine.load(modelFolder: folder)
                settingsStore.modelDownloaded = true
                appState.status = .idle
                closeDownloadWindow()
                requestPermissions()
            } catch {
                appState.status = .error(error.localizedDescription)
            }
        }
    }

    private func showDownloadWindow() {
        let view = ModelDownloadView(modelManager: modelManager) { [weak self] in
            Task { @MainActor [weak self] in
                await self?.triggerDownload()
            }
        }

        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.title = "LocalFlow"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 380, height: 280))
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        downloadWindow = window
    }

    private func closeDownloadWindow() {
        downloadWindow?.close()
        downloadWindow = nil
    }

    // MARK: - Permissions

    private func requestPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)

        if !CGPreflightListenEventAccess() {
            CGRequestListenEventAccess()
        }
    }

    // MARK: - Wiring

    private func wireAudioToWaveform() {
        audioRecorder.onAmplitudeUpdate = { [weak self] amplitudes in
            self?.appState.waveformAmplitudes = amplitudes
        }
    }

    private func wireRecordingCallbacks() {
        appState.onPauseRecording  = { [weak self] in self?.pauseRecording() }
        appState.onResumeRecording = { [weak self] in self?.resumeRecording() }
        appState.onStopRecording   = { [weak self] in
            // Reset hotkey state so next Globe press starts a new session
            self?.hotKeyManager.resetState()
            self?.endRecording()
        }
    }

    private func wireHotKeys() {
        let useGlobe = settingsStore.hotKeyUsesGlobe
        print("[AppDelegate] wireHotKeys — useGlobe=\(useGlobe), status=\(appState.status)")
        hotKeyManager.configure(useGlobe: useGlobe)

        hotKeyManager.onRecordingStart = { [weak self] in
            DispatchQueue.main.async {
                print("[AppDelegate] onRecordingStart fired — status=\(self?.appState.status as Any)")
                self?.beginRecording()
            }
        }
        hotKeyManager.onRecordingStop = { [weak self] in
            DispatchQueue.main.async { self?.endRecording() }
        }
    }

    @objc private func onSettingsChanged() {
        wireHotKeys()
        if settingsStore.enableAppCapture && textCaptureEngine == nil {
            startTextCapture()
        } else if !settingsStore.enableAppCapture {
            textCaptureEngine?.stop()
            textCaptureEngine = nil
        }
    }

    // MARK: - Text Capture

    private func startTextCapture() {
        let engine = AppTextCaptureEngine(settingsStore: settingsStore)
        textCaptureEngine = engine
        engine.start { [weak self] text, appName in
            guard let self else { return }
            let record = TranscriptionRecord(
                text: text, durationSeconds: 0, language: "auto",
                targetApp: appName, source: .appCapture
            )
            self.historyStore.append(record)
            self.embedAndIndex(id: record.id, text: text, language: "auto")
        }
    }

    // MARK: - Embedding helper

    private func embedAndIndex(id: UUID, text: String, language: String) {
        Task.detached(priority: .background) { [weak self] in
            guard let self else { return }
            let chunks = EmbeddingEngine.chunkText(text)
            var vecs: [[Float]] = []
            for chunk in chunks {
                if let v = await EmbeddingEngine.shared.embed(chunk, language: language) {
                    vecs.append(v)
                }
            }
            let builtVecs = vecs
            await MainActor.run {
                if !builtVecs.isEmpty {
                    self.historyStore.addToSemanticIndex(id: id, vectors: builtVecs)
                }
            }
        }
    }

    // MARK: - Recording State Machine

    private func beginRecording() {
        guard case .idle = appState.status else { return }

        do {
            try audioRecorder.startRecording()
            recordingStartTime = .now
            appState.status = .recording
            appState.isRecording = true
            floatingPanel?.showCentered()
            menuBarController.updateIcon(for: .recording)
        } catch {
            appState.status = .error(error.localizedDescription)
        }
    }

    private func pauseRecording() {
        guard case .recording = appState.status else { return }
        audioRecorder.pauseRecording()
        appState.status = .paused
        menuBarController.updateIcon(for: .paused)
    }

    private func resumeRecording() {
        guard case .paused = appState.status else { return }
        do {
            try audioRecorder.resumeRecording()
            appState.status = .recording
            menuBarController.updateIcon(for: .recording)
        } catch {
            appState.status = .error(error.localizedDescription)
        }
    }

    private func endRecording() {
        // Accept both .recording and .paused
        switch appState.status {
        case .recording, .paused: break
        default: return
        }

        let samples = audioRecorder.stopRecording()
        let duration = Date.now.timeIntervalSince(recordingStartTime)

        let minSamples = Int(16_000 * 0.3)
        guard samples.count > minSamples else {
            appState.status = .idle
            appState.isRecording = false
            floatingPanel?.hide()
            menuBarController.updateIcon(for: .idle)
            return
        }

        appState.transcriptionEstimatedDuration = max(duration / 6.0, 1.5)
        appState.status = .transcribing
        appState.isRecording = false
        menuBarController.updateIcon(for: .transcribing)

        let language = settingsStore.language
        let useClipboard = settingsStore.useClipboardFallback
        let targetApp = NSWorkspace.shared.frontmostApplication?.localizedName

        Task {
            do {
                let text = try await transcriptionEngine.transcribe(
                    audioSamples: samples,
                    language: language
                )

                await MainActor.run {
                    appState.lastTranscription = text
                    appState.status = .idle
                    self.floatingPanel?.hide()
                    self.menuBarController.updateIcon(for: .idle)

                    if !text.isEmpty {
                        let record = TranscriptionRecord(
                            text: text,
                            durationSeconds: duration,
                            language: language,
                            targetApp: targetApp
                        )
                        self.historyStore.append(record)
                        self.embedAndIndex(id: record.id, text: text, language: language)
                    }
                }

                if !text.isEmpty {
                    try? await Task.sleep(nanoseconds: 80_000_000)
                    textInjector.inject(text: text, useClipboard: useClipboard)
                }
            } catch {
                await MainActor.run {
                    appState.status = .error(error.localizedDescription)
                    self.floatingPanel?.hide()
                    self.menuBarController.updateIcon(for: .error(error.localizedDescription))
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        if case .error = self.appState.status {
                            self.appState.status = .idle
                            self.menuBarController.updateIcon(for: .idle)
                        }
                    }
                }
            }
        }
    }
}
