import AppKit
import ApplicationServices

@MainActor
final class AppTextCaptureEngine {
    private let settingsStore: SettingsStore
    private var pollTimer: Timer?
    private var capturedBlocks: [String: Set<String>] = [:]
    private var onCapture: ((String, String) -> Void)?

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
    }

    func start(onCapture: @escaping (String, String) -> Void) {
        self.onCapture = onCapture
        guard pollTimer == nil else { return }
        pollTimer = Timer.scheduledTimer(
            withTimeInterval: settingsStore.capturePollingInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.poll()
            }
        }
    }

    func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    // MARK: - Polling

    private func poll() {
        guard settingsStore.enableAppCapture else { return }
        guard AXIsProcessTrusted() else { return }

        guard let frontApp = NSWorkspace.shared.frontmostApplication,
              let bundleID = frontApp.bundleIdentifier,
              settingsStore.monitoredBundleIDs.contains(bundleID) else { return }

        let pid = frontApp.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)

        var texts: [String] = []
        collectTexts(from: appElement, into: &texts)

        guard !texts.isEmpty else { return }

        if let newContent = diffAndCapture(bundleID: bundleID, currentTexts: texts) {
            let appName = frontApp.localizedName ?? bundleID
            onCapture?(newContent, appName)
        }
    }

    // MARK: - Tree walking

    private func collectTexts(from element: AXUIElement, into texts: inout [String], depth: Int = 0) {
        guard depth < 50 else { return }

        var roleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef)
        let role = roleRef as? String

        // Skip editable fields (user input area)
        if role == "AXTextArea" || role == "AXTextField" {
            var editableRef: CFTypeRef?
            AXUIElementCopyAttributeValue(element, "AXEditable" as CFString, &editableRef)
            if let editable = editableRef as? Bool, editable { return }
        }

        if role == "AXStaticText" {
            var valueRef: CFTypeRef?
            AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &valueRef)
            if let text = valueRef as? String {
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                let wordCount = trimmed.split(separator: " ").count
                if wordCount >= 3, !isUIChrome(trimmed) {
                    texts.append(trimmed)
                }
            }
            return
        }

        var childrenRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenRef)
        guard let children = childrenRef as? [AXUIElement] else { return }
        for child in children {
            collectTexts(from: child, into: &texts, depth: depth + 1)
        }
    }

    private func isUIChrome(_ text: String) -> Bool {
        let lowered = text.lowercased()
        let chromePatterns = ["copy", "retry", "edit", "delete", "send", "cancel",
                              "copiar", "reintentar", "editar", "eliminar", "enviar", "cancelar"]
        if chromePatterns.contains(lowered) { return true }
        // Timestamps like "2:34 PM", "14:32"
        let timePattern = #"^\d{1,2}:\d{2}\s*(AM|PM|am|pm)?$"#
        if text.range(of: timePattern, options: .regularExpression) != nil { return true }
        return false
    }

    // MARK: - Diff

    private func diffAndCapture(bundleID: String, currentTexts: [String]) -> String? {
        let known = capturedBlocks[bundleID] ?? Set()
        let newTexts = currentTexts.filter { !known.contains($0) }

        guard !newTexts.isEmpty else { return nil }

        let joined = newTexts.joined(separator: "\n")
        let wordCount = joined.split(separator: " ").count
        guard wordCount >= 10 else { return nil }

        var updated = known
        for text in currentTexts { updated.insert(text) }

        // Cap at 2000 entries — evict oldest by rebuilding from current snapshot
        if updated.count > 2000 {
            updated = Set(currentTexts.suffix(1500))
        }

        capturedBlocks[bundleID] = updated
        return joined
    }
}
