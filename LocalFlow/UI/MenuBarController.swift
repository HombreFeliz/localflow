import AppKit

final class MenuBarController {
    private var statusItem: NSStatusItem?
    private var openSettingsCallback: (() -> Void)?

    func setup(openSettings: @escaping () -> Void) {
        self.openSettingsCallback = openSettings

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = makeIcon("waveform.and.mic")
            button.toolTip = "LocalFlow"
        }

        buildMenu()
    }

    func updateIcon(for status: AppStatus) {
        let symbolName: String
        switch status {
        case .recording:
            symbolName = "waveform.circle.fill"
        case .transcribing:
            symbolName = "ellipsis.circle"
        case .downloadingModel:
            symbolName = "arrow.down.circle"
        case .error:
            symbolName = "exclamationmark.circle"
        default:
            symbolName = "waveform.and.mic"
        }
        statusItem?.button?.image = makeIcon(symbolName)
    }

    private func buildMenu() {
        let menu = NSMenu()

        let settingsItem = NSMenuItem(
            title: "Ajustes...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Salir de LocalFlow",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    @objc private func openSettings() {
        openSettingsCallback?()
    }

    private func makeIcon(_ name: String) -> NSImage? {
        let img = NSImage(systemSymbolName: name, accessibilityDescription: nil)
        img?.isTemplate = true
        return img
    }
}
