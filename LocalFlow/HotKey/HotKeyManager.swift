import KeyboardShortcuts
import Foundation

extension KeyboardShortcuts.Name {
    static let dictate = Self("localflow_dictate")
}

final class HotKeyManager {
    var onRecordingStart: (() -> Void)?
    var onRecordingStop: (() -> Void)?

    private let globeMonitor = GlobeKeyMonitor()
    private var useGlobe: Bool = true
    private var isCurrentlyRecording = false
    private var isHoldSession = false

    func configure(useGlobe: Bool) {
        self.useGlobe = useGlobe
        rebind()
    }

    /// Reset recording state — call this when the UI stops recording (not the hotkey),
    /// so the next Globe press starts a new session instead of trying to stop one.
    func resetState() {
        isCurrentlyRecording = false
        isHoldSession = false
    }

    private func rebind() {
        globeMonitor.stop()
        KeyboardShortcuts.disable(.dictate)

        if useGlobe {
            setupGlobeHandlers()
            globeMonitor.start()
        } else {
            setupKeyboardShortcutHandlers()
        }
    }

    private func setupGlobeHandlers() {
        globeMonitor.onHoldStart = { [weak self] in
            guard let self, !isCurrentlyRecording else { return }
            isHoldSession = true
            isCurrentlyRecording = true
            onRecordingStart?()
        }

        globeMonitor.onHoldEnd = { [weak self] in
            guard let self, isHoldSession else { return }
            isHoldSession = false
            isCurrentlyRecording = false
            onRecordingStop?()
        }
    }

    private func setupKeyboardShortcutHandlers() {
        KeyboardShortcuts.onKeyDown(for: .dictate) { [weak self] in
            guard let self, !isCurrentlyRecording else { return }
            isCurrentlyRecording = true
            onRecordingStart?()
        }
        KeyboardShortcuts.onKeyUp(for: .dictate) { [weak self] in
            guard let self, isCurrentlyRecording else { return }
            isCurrentlyRecording = false
            onRecordingStop?()
        }
    }

    func forceStop() {
        if isCurrentlyRecording {
            isCurrentlyRecording = false
            isHoldSession = false
            onRecordingStop?()
        }
    }
}
