import AppKit
import SwiftUI

final class NotePanel: NSPanel {
    var noteId: UUID?

    init(noteId: UUID, frame: NSRect) {
        self.noteId = noteId

        super.init(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        configure()
    }

    private func configure() {
        isMovableByWindowBackground = true
        isFloatingPanel = false
        hidesOnDeactivate = false
        animationBehavior = .utilityWindow

        // Normal window behavior by default - goes behind other windows
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        level = .normal

        minSize = NSSize(width: 150, height: 24)  // Allow collapsed height
        maxSize = NSSize(width: 500, height: 800)

        backgroundColor = .clear
        isOpaque = false
        hasShadow = false  // We handle shadow in SwiftUI

        // Enable resizing
        styleMask.insert(.resizable)
    }

    func updateFloatingLevel(isPinned: Bool) {
        if isPinned {
            level = .floating
            isFloatingPanel = true
            collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        } else {
            level = .normal
            isFloatingPanel = false
            collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        }
    }

    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return false
    }

    // Center the window on the main screen
    func centerOnScreen() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let windowFrame = frame

        let newOriginX = screenFrame.midX - (windowFrame.width / 2)
        let newOriginY = screenFrame.midY - (windowFrame.height / 2)

        setFrameOrigin(NSPoint(x: newOriginX, y: newOriginY))
    }
}
