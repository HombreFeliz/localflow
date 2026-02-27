import AppKit
import SwiftUI

final class ChatWindowController: NSObject {
    private var window: NSWindow?
    private let historyStore: HistoryStore

    init(historyStore: HistoryStore) {
        self.historyStore = historyStore
    }

    func show() {
        if window == nil { buildWindow() }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func buildWindow() {
        let view = ChatView(historyStore: historyStore)
        let hosting = NSHostingController(rootView: view)

        let w = NSWindow(contentViewController: hosting)
        w.title = "LocalFlow Chat"
        w.styleMask = [.titled, .closable, .resizable, .miniaturizable]
        w.setContentSize(NSSize(width: 480, height: 550))
        w.minSize = NSSize(width: 480, height: 500)
        w.center()
        w.isReleasedWhenClosed = false
        window = w
    }
}
