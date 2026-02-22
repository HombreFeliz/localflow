import AppKit
import SwiftUI

final class FloatingPanel: NSPanel {
    private var hostingView: NSHostingView<AnyView>?

    init(appState: AppState) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 64),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )

        level = .floating
        isFloatingPanel = true
        hidesOnDeactivate = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        titlebarAppearsTransparent = true
        titleVisibility = .hidden

        let overlayView = RecordingOverlayView()
            .environment(appState)

        let hosting = NSHostingView(rootView: AnyView(overlayView))
        hosting.frame = contentView?.bounds ?? NSRect(x: 0, y: 0, width: 220, height: 64)
        hosting.autoresizingMask = [.width, .height]
        contentView = hosting
        self.hostingView = hosting
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func showCentered() {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let screenFrame = screen.visibleFrame
        let panelWidth = frame.width

        let x = screenFrame.midX - panelWidth / 2
        let y = screenFrame.minY + 80

        setFrameOrigin(NSPoint(x: x, y: y))
        alphaValue = 0
        orderFront(nil)

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            animator().alphaValue = 1.0
        }
    }

    func hide() {
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.15
            animator().alphaValue = 0
        }, completionHandler: {
            self.orderOut(nil)
            self.alphaValue = 1.0
        })
    }
}
