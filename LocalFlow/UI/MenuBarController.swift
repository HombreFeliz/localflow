import AppKit

@MainActor
final class MenuBarController {
    private var statusItem: NSStatusItem?
    private var settingsStore: SettingsStore?
    private var cleaningItem: NSMenuItem?
    private var ollamaStatusItem: NSMenuItem?
    private var ollamaTask: Task<Void, Never>?

    func setup(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
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
        case .recording:        symbolName = "waveform.circle.fill"
        case .transcribing:     symbolName = "ellipsis.circle"
        case .cleaning:         symbolName = "sparkles"
        case .downloadingModel: symbolName = "arrow.down.circle"
        case .error:            symbolName = "exclamationmark.circle"
        default:                symbolName = "waveform.and.mic"
        }
        statusItem?.button?.image = makeIcon(symbolName)
    }

    // Llamar cuando cambia cleaningEnabled desde fuera (para sincronizar el checkmark)
    func refreshCleaningState() {
        cleaningItem?.state = (settingsStore?.cleaningEnabled == true) ? .on : .off
        updateOllamaStatus()
    }

    private func buildMenu() {
        let menu = NSMenu()
        menu.delegate = self as? NSMenuDelegate

        // — Sección Mejora de texto —
        let cleaningItem = NSMenuItem(
            title: "Mejorar texto con IA",
            action: #selector(toggleCleaning),
            keyEquivalent: ""
        )
        cleaningItem.target = self
        cleaningItem.state = (settingsStore?.cleaningEnabled == true) ? .on : .off
        menu.addItem(cleaningItem)
        self.cleaningItem = cleaningItem

        // Estado de Ollama (solo visible si cleaning está activado)
        let ollamaItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        ollamaItem.isEnabled = false
        menu.addItem(ollamaItem)
        self.ollamaStatusItem = ollamaItem
        updateOllamaStatus()

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

        // — Salir —
        let quitItem = NSMenuItem(
            title: "Salir de LocalFlow",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    // MARK: - Acciones

    @objc private func toggleCleaning() {
        guard let store = settingsStore else { return }
        store.cleaningEnabled.toggle()
        cleaningItem?.state = store.cleaningEnabled ? .on : .off
        updateOllamaStatus()

        // Si se acaba de activar, verificar Ollama en background
        if store.cleaningEnabled {
            checkOllamaAsync()
        }
    }

    @objc private func setLanguage(_ sender: NSMenuItem) {
        guard let lang = sender.representedObject as? String else { return }
        settingsStore?.language = lang
        // Actualizar checkmarks del submenú
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

    @objc private func openOllamaHelp() {
        NSWorkspace.shared.open(URL(string: "https://github.com/HombreFeliz/localflow#limpieza-de-texto-con-ollama")!)
    }

    // MARK: - Ollama status

    private func updateOllamaStatus() {
        guard let store = settingsStore else { return }

        if !store.cleaningEnabled {
            ollamaStatusItem?.isHidden = true
            return
        }

        ollamaStatusItem?.isHidden = false
        ollamaStatusItem?.attributedTitle = makeStatusTitle("   ○ Comprobando Ollama...", color: .secondaryLabelColor)
        checkOllamaAsync()
    }

    private func checkOllamaAsync() {
        guard let store = settingsStore else { return }
        ollamaTask?.cancel()
        ollamaTask = Task { @MainActor in
            let engine = TextCleaningEngine()
            let available = await engine.isOllamaAvailable(host: store.ollamaHost)
            guard !Task.isCancelled else { return }

            if available {
                ollamaStatusItem?.attributedTitle = makeStatusTitle("   ● Ollama listo", color: .systemGreen)
                ollamaStatusItem?.action = nil
                ollamaStatusItem?.isEnabled = false
            } else {
                ollamaStatusItem?.attributedTitle = makeStatusTitle("   ○ Ollama no detectado — Ver instrucciones", color: .systemRed)
                ollamaStatusItem?.action = #selector(openOllamaHelp)
                ollamaStatusItem?.target = self
                ollamaStatusItem?.isEnabled = true
            }
        }
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

    private func makeStatusTitle(_ text: String, color: NSColor) -> NSAttributedString {
        NSAttributedString(string: text, attributes: [
            .foregroundColor: color,
            .font: NSFont.menuFont(ofSize: 13)
        ])
    }

    private func makeIcon(_ name: String) -> NSImage? {
        let img = NSImage(systemSymbolName: name, accessibilityDescription: nil)
        img?.isTemplate = true
        return img
    }
}
