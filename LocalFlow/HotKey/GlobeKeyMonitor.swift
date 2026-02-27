import CoreGraphics
import Foundation

final class GlobeKeyMonitor {
    var onHoldStart: (() -> Void)?   // Globe pressed — hold-to-talk begins
    var onHoldEnd: (() -> Void)?     // Globe released — hold-to-talk ends

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isGlobeDown = false

    func start() {
        guard eventTap == nil else { return }

        // listenOnly — safer; system cannot disable it for being too slow
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
        isGlobeDown = false
    }

    fileprivate func handleFlagsChanged(isGlobeCurrentlyDown: Bool) {
        if isGlobeCurrentlyDown && !isGlobeDown {
            isGlobeDown = true
            DispatchQueue.main.async { [weak self] in self?.onHoldStart?() }
        } else if !isGlobeCurrentlyDown && isGlobeDown {
            isGlobeDown = false
            DispatchQueue.main.async { [weak self] in self?.onHoldEnd?() }
        }
    }
}

private func globeEventCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon = refcon else {
        return Unmanaged.passRetained(event)
    }

    let monitor = Unmanaged<GlobeKeyMonitor>.fromOpaque(refcon).takeUnretainedValue()

    if type == .flagsChanged,
       event.getIntegerValueField(.keyboardEventKeycode) == 63 {
        let isGlobeDown = event.flags.contains(.maskSecondaryFn)
        monitor.handleFlagsChanged(isGlobeCurrentlyDown: isGlobeDown)
    }

    return Unmanaged.passRetained(event)
}
