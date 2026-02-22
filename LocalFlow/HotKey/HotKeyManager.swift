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
    private var isToggleMode: Bool = false
    private var isCurrentlyRecording = false

    func configure(useGlobe: Bool, isToggleMode: Bool) {
        self.useGlobe = useGlobe
        self.isToggleMode = isToggleMode
        rebind()
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
        if isToggleMode {
            globeMonitor.onPress = { [weak self] in
                guard let self else { return }
                if isCurrentlyRecording {
                    isCurrentlyRecording = false
                    onRecordingStop?()
                } else {
                    isCurrentlyRecording = true
                    onRecordingStart?()
                }
            }
            globeMonitor.onRelease = nil
        } else {
            globeMonitor.onPress = { [weak self] in
                guard let self else { return }
                isCurrentlyRecording = true
                onRecordingStart?()
            }
            globeMonitor.onRelease = { [weak self] in
                guard let self, isCurrentlyRecording else { return }
                isCurrentlyRecording = false
                onRecordingStop?()
            }
        }
    }

    private func setupKeyboardShortcutHandlers() {
        if isToggleMode {
            KeyboardShortcuts.onKeyDown(for: .dictate) { [weak self] in
                guard let self else { return }
                if isCurrentlyRecording {
                    isCurrentlyRecording = false
                    onRecordingStop?()
                } else {
                    isCurrentlyRecording = true
                    onRecordingStart?()
                }
            }
        } else {
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
    }

    func forceStop() {
        if isCurrentlyRecording {
            isCurrentlyRecording = false
            onRecordingStop?()
        }
    }
}
