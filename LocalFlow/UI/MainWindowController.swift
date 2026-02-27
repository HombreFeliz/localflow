import AppKit
import SwiftUI

@MainActor
final class MainWindowController: NSWindowController, NSWindowDelegate {
    private let historyStore: HistoryStore
    private let settingsStore: SettingsStore
    private let appState: AppState

    init(historyStore: HistoryStore, settingsStore: SettingsStore, appState: AppState) {
        self.historyStore = historyStore
        self.settingsStore = settingsStore
        self.appState = appState

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 520),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .unifiedTitleAndToolbar],
            backing: .buffered,
            defer: false
        )
        window.title = "LocalFlow"
        window.minSize = NSSize(width: 560, height: 400)
        window.center()
        window.setFrameAutosaveName("LocalFlowMainWindow")
        window.toolbarStyle = .unified

        super.init(window: window)
        window.delegate = self

        let mainView = MainView(historyStore: historyStore, settingsStore: settingsStore, appState: appState)
        window.contentView = NSHostingView(rootView: mainView)
    }

    required init?(coder: NSCoder) { fatalError() }

    func show() {
        NSApp.setActivationPolicy(.regular)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
