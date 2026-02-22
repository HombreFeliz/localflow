import CoreGraphics
import Foundation

final class GlobeKeyMonitor {
    var onPress: (() -> Void)?
    var onRelease: (() -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isCurrentlyDown = false

    func start() {
        guard eventTap == nil else { return }

        let eventMask: CGEventMask = (1 << CGEventType.flagsChanged.rawValue)
        let selfPtr = Unmanaged.passRetained(self).toOpaque()

        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: globeEventCallback,
            userInfo: selfPtr
        )

        guard let tap = eventTap else {
            Unmanaged<GlobeKeyMonitor>.fromOpaque(selfPtr).release()
            return
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        if let src = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), src, .commonModes)
        }
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let src = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), src, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        isCurrentlyDown = false
    }

    fileprivate func handleFlagsChanged(isGlobeDown: Bool) {
        if isGlobeDown && !isCurrentlyDown {
            isCurrentlyDown = true
            DispatchQueue.main.async { [weak self] in self?.onPress?() }
        } else if !isGlobeDown && isCurrentlyDown {
            isCurrentlyDown = false
            DispatchQueue.main.async { [weak self] in self?.onRelease?() }
        }
    }
}

private func globeEventCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard type == .flagsChanged,
          event.getIntegerValueField(.keyboardEventKeycode) == 63,
          let refcon = refcon else {
        return Unmanaged.passRetained(event)
    }

    let monitor = Unmanaged<GlobeKeyMonitor>.fromOpaque(refcon).takeUnretainedValue()
    let isGlobeDown = event.flags.contains(.maskSecondaryFn)
    monitor.handleFlagsChanged(isGlobeDown: isGlobeDown)

    return Unmanaged.passRetained(event)
}
