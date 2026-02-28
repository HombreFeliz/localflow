import AppKit

@MainActor
final class MenuBarController {
    private var statusItem: NSStatusItem?
    private var settingsStore: SettingsStore?
    private var openMainWindowCallback: (() -> Void)?
    private var openChatCallback: (() -> Void)?

    func setup(settingsStore: SettingsStore, openMainWindow: @escaping () -> Void, openChat: @escaping () -> Void = {}) {
        self.settingsStore = settingsStore
        self.openMainWindowCallback = openMainWindow
        self.openChatCallback = openChat

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = makeIcon("waveform.and.mic")
            button.toolTip = "LocalFlow"
            button.action = #selector(handleIconClick)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        buildMenu()
    }

    func updateIcon(for status: AppStatus) {
        let symbolName: String
        switch status {
        case .recording:        symbolName = "waveform.circle.fill"
        case .paused:           symbolName = "pause.circle.fill"
        case .transcribing:     symbolName = "ellipsis.circle"
        case .downloadingModel: symbolName = "arrow.down.circle"
        case .error:            symbolName = "exclamationmark.circle"
        default:                symbolName = "waveform.and.mic"
        }
        statusItem?.button?.image = makeIcon(symbolName)
    }

    @objc private func handleIconClick() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            statusItem?.menu = buildMenuObject()
            statusItem?.button?.performClick(nil)
            statusItem?.menu = nil
        } else {
            openMainWindowCallback?()
        }
    }

    private func buildMenu() {
        statusItem?.menu = nil  // click izquierdo abre ventana, no menú
    }

    private func buildMenuObject() -> NSMenu {
        let menu = NSMenu()

        let openItem = NSMenuItem(title: "Abrir LocalFlow", action: #selector(openMainWindow), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)

        menu.addItem(.separator())

        // — Idioma —
        let languageMenu = NSMenu()
        let languages: [(String, String)] = [
            ("Detectar automáticamente", "auto"),
            ("Español", "es"),
            ("English", "en"),
            ("Català", "ca"),
            ("Français", "fr"),
            ("Deutsch", "de"),
            ("Português", "pt"),
            ("Italiano", "it"),
            ("日本語", "ja"),
            ("中文", "zh"),
        ]
        for (title, tag) in languages {
            let item = NSMenuItem(title: title, action: #selector(setLanguage(_:)), keyEquivalent: "")
            item.representedObject = tag
            item.target = self
            if settingsStore?.language == tag { item.state = .on }
            languageMenu.addItem(item)
        }
        let languageItem = NSMenuItem(title: "Idioma", action: nil, keyEquivalent: "")
        languageItem.submenu = languageMenu
        menu.addItem(languageItem)

        // — Modo de grabación —
        let modeMenu = NSMenu()
        let holdItem = NSMenuItem(title: "Mantener presionado", action: #selector(setModeHold), keyEquivalent: "")
        holdItem.target = self
        holdItem.state = (settingsStore?.recordingMode == "holdToTalk") ? .on : .off
        modeMenu.addItem(holdItem)

        let toggleItem = NSMenuItem(title: "Alternar (pulsar una vez)", action: #selector(setModeToggle), keyEquivalent: "")
        toggleItem.target = self
        toggleItem.state = (settingsStore?.recordingMode == "toggle") ? .on : .off
        modeMenu.addItem(toggleItem)

        let modeItem = NSMenuItem(title: "Modo de grabación", action: nil, keyEquivalent: "")
        modeItem.submenu = modeMenu
        menu.addItem(modeItem)

        menu.addItem(.separator())

        // — Chat —
        let chatItem = NSMenuItem(title: "Abrir Chat", action: #selector(openChat), keyEquivalent: "")
        chatItem.target = self
        menu.addItem(chatItem)

        // — Ajustes —
        let settingsItem = NSMenuItem(title: "Ajustes...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        // — Salir —
        let quitItem = NSMenuItem(
            title: "Salir de LocalFlow",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        return menu
    }

    // MARK: - Acciones

    @objc private func openMainWindow() {
        openMainWindowCallback?()
    }

    @objc private func openChat() {
        openChatCallback?()
    }

    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func setLanguage(_ sender: NSMenuItem) {
        guard let lang = sender.representedObject as? String else { return }
        settingsStore?.language = lang
        sender.menu?.items.forEach { $0.state = ($0.representedObject as? String == lang) ? .on : .off }
        NotificationCenter.default.post(name: .settingsChanged, object: nil)
    }

    @objc private func setModeHold() {
        settingsStore?.recordingMode = "holdToTalk"
        rebuildModeMenu()
        NotificationCenter.default.post(name: .settingsChanged, object: nil)
    }

    @objc private func setModeToggle() {
        settingsStore?.recordingMode = "toggle"
        rebuildModeMenu()
        NotificationCenter.default.post(name: .settingsChanged, object: nil)
    }

    // MARK: - Helpers

    private func rebuildModeMenu() {
        guard let menu = statusItem?.menu,
              let modeItem = menu.items.first(where: { $0.title == "Modo de grabación" }),
              let modeMenu = modeItem.submenu else { return }
        let isHold = settingsStore?.recordingMode == "holdToTalk"
        modeMenu.items[0].state = isHold ? .on : .off
        modeMenu.items[1].state = isHold ? .off : .on
    }

    private func makeIcon(_ name: String) -> NSImage? {
        let img = NSImage(systemSymbolName: name, accessibilityDescription: nil)
        img?.isTemplate = true
        return img
    }
}
