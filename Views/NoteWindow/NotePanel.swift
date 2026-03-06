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

        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        level = .floating

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
            level = .statusBar
            isFloatingPanel = true
            collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        } else {
            level = .floating
            isFloatingPanel = true
            collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        }
    }

    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return false
    }

    override func keyDown(with event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        if flags == .command {
            switch event.charactersIgnoringModifiers {
            case "w":
                // Cmd+W: close window
                close()
                return
            case "f":
                // Cmd+F: find in note - forward to text view
                if let textView = findTextView(in: contentView) {
                    textView.performTextFinderAction(NSTextFinder.Action.showFindInterface)
                }
                return
            default:
                break
            }
        }

        super.keyDown(with: event)
    }

    private func findTextView(in view: NSView?) -> NSTextView? {
        guard let view = view else { return nil }
        if let textView = view as? NSTextView {
            return textView
        }
        for subview in view.subviews {
            if let found = findTextView(in: subview) {
                return found
            }
        }
        return nil
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
