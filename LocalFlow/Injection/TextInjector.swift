import CoreGraphics
import AppKit

final class TextInjector {
    func inject(text: String, useClipboard: Bool = false) {
        if useClipboard {
            injectViaPaste(text: text)
        } else {
            injectDirect(text: text)
        }
    }

    private func injectDirect(text: String) {
        let utf16 = Array(text.utf16)
        guard !utf16.isEmpty else { return }

        let chunkSize = 40
        var offset = 0

        while offset < utf16.count {
            let end = min(offset + chunkSize, utf16.count)
            let chunk = Array(utf16[offset..<end])

            if let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) {
                event.flags = .maskNonCoalesced
                event.keyboardSetUnicodeString(stringLength: chunk.count, unicodeString: chunk)
                event.post(tap: .cghidEventTap)
            }
            if let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) {
                keyUp.flags = .maskNonCoalesced
                keyUp.post(tap: .cghidEventTap)
            }
            offset += chunkSize

            if offset < utf16.count {
                Thread.sleep(forTimeInterval: 0.01)
            }
        }
    }

    private func injectViaPaste(text: String) {
        let pasteboard = NSPasteboard.general
        let previous = pasteboard.string(forType: .string)

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        let src = CGEventSource(stateID: .combinedSessionState)

        let cmdVDown = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: true)
        cmdVDown?.flags = .maskCommand
        cmdVDown?.post(tap: .cghidEventTap)

        let cmdVUp = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: false)
        cmdVUp?.flags = .maskCommand
        cmdVUp?.post(tap: .cghidEventTap)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            pasteboard.clearContents()
            if let prev = previous {
                pasteboard.setString(prev, forType: .string)
            }
        }
    }
}
