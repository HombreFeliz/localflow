import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    let settingsStore = SettingsStore()

    private let audioRecorder = AudioRecorder()
    private let transcriptionEngine = TranscriptionEngine()
    private let textCleaner = TextCleaningEngine()
    let modelManager = ModelManager()
    private let hotKeyManager = HotKeyManager()
    private let textInjector = TextInjector()
    private let menuBarController = MenuBarController()

    private var floatingPanel: FloatingPanel?
    private var downloadWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        floatingPanel = FloatingPanel(appState: appState)

        menuBarController.setup { [weak self] in
            self?.openSettings()
        }

        wireAudioToWaveform()
        wireHotKeys()

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

    // MARK: - Model Loading

    @MainActor
    private func startupModelCheck() async {
        if settingsStore.modelDownloaded {
            appState.status = .downloadingModel(progress: 0)
            if let folder = modelManager.findLocalModel() {
                do {
                    try await transcriptionEngine.load(modelFolder: folder)
                    appState.status = .idle
                } catch {
                    await triggerDownload()
                }
            } else {
                settingsStore.modelDownloaded = false
                await triggerDownload()
            }
        } else {
            await triggerDownload()
        }
    }

    @MainActor
    private func triggerDownload() async {
        showDownloadWindow()
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

    private func wireHotKeys() {
        let useGlobe = settingsStore.hotKeyUsesGlobe
        let isToggle = settingsStore.recordingMode == "toggle"
        hotKeyManager.configure(useGlobe: useGlobe, isToggleMode: isToggle)

        hotKeyManager.onRecordingStart = { [weak self] in
            DispatchQueue.main.async { self?.beginRecording() }
        }
        hotKeyManager.onRecordingStop = { [weak self] in
            DispatchQueue.main.async { self?.endRecording() }
        }
    }

    @objc private func onSettingsChanged() {
        wireHotKeys()
    }

    // MARK: - Recording State Machine

    private func beginRecording() {
        guard case .idle = appState.status else { return }

        do {
            try audioRecorder.startRecording()
            appState.status = .recording
            appState.isRecording = true
            floatingPanel?.showCentered()
            menuBarController.updateIcon(for: .recording)
        } catch {
            appState.status = .error(error.localizedDescription)
        }
    }

    private func endRecording() {
        guard case .recording = appState.status else { return }

        let samples = audioRecorder.stopRecording()

        let minSamples = Int(16_000 * 0.3)
        guard samples.count > minSamples else {
            appState.status = .idle
            appState.isRecording = false
            floatingPanel?.hide()
            menuBarController.updateIcon(for: .idle)
            return
        }

        appState.status = .transcribing
        appState.isRecording = false
        menuBarController.updateIcon(for: .transcribing)

        let language = settingsStore.language
        let useClipboard = settingsStore.useClipboardFallback
        let cleaningEnabled = settingsStore.cleaningEnabled
        let ollamaModel = settingsStore.ollamaModel
        let ollamaHost = settingsStore.ollamaHost

        Task {
            do {
                let rawText = try await transcriptionEngine.transcribe(
                    audioSamples: samples,
                    language: language
                )

                var finalText = rawText

                if !rawText.isEmpty && cleaningEnabled {
                    await MainActor.run {
                        appState.status = .cleaning
                        self.menuBarController.updateIcon(for: .cleaning)
                    }
                    finalText = await textCleaner.clean(
                        text: rawText,
                        language: language,
                        model: ollamaModel,
                        host: ollamaHost
                    )
                }

                await MainActor.run {
                    appState.lastTranscription = finalText
                    appState.status = .idle
                    self.floatingPanel?.hide()
                    self.menuBarController.updateIcon(for: .idle)
                }

                if !finalText.isEmpty {
                    try? await Task.sleep(nanoseconds: 80_000_000)
                    textInjector.inject(text: finalText, useClipboard: useClipboard)
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

    // MARK: - Settings Window

    func openSettings() {
        // En macOS 14+ buscar la ventana de Settings ya creada por SwiftUI
        if let win = NSApp.windows.first(where: { $0.identifier?.rawValue.contains("Settings") == true }) {
            win.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        // Fallback: usar el selector clásico (crea la ventana si no existe)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

