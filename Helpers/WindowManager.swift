import AppKit
import Foundation

@MainActor
final class WindowManager {
    static let shared = WindowManager()

    private var windowControllers: [UUID: NoteWindowController] = [:]
    private let store = NoteStore.shared

    private init() {}

    func openWindow(for noteId: UUID, isNewNote: Bool = false) {
        if let existingController = windowControllers[noteId] {
            existingController.showWindow()
            return
        }

        let controller = NoteWindowController(noteId: noteId, store: store, isNewNote: isNewNote)
        windowControllers[noteId] = controller
        controller.showWindow()
    }

    func createAndOpenNewNote(color: NoteColor = .silver) {
        let note = store.createNote(color: color)
        openWindow(for: note.id, isNewNote: true)
    }

    func removeWindow(for noteId: UUID) {
        windowControllers.removeValue(forKey: noteId)
    }

    func closeWindow(for noteId: UUID) {
        windowControllers[noteId]?.close()
        windowControllers.removeValue(forKey: noteId)
    }

    func closeAllWindows() {
        for (_, controller) in windowControllers {
            controller.close()
        }
        windowControllers.removeAll()
    }

    func showAllNotes() {
        for note in store.notes {
            openWindow(for: note.id, isNewNote: false)
        }
    }

    func hideAllNotes() {
        for (_, controller) in windowControllers {
            controller.window?.orderOut(nil)
        }
    }

    func toggleAllNotes() {
        let anyVisible = windowControllers.values.contains { controller in
            controller.window?.isVisible == true
        }

        if anyVisible {
            hideAllNotes()
        } else {
            showAllNotes()
        }
    }

    func restoreWindows() {
        for note in store.notes {
            // Validate window position is on a connected screen
            validateAndFixFrame(for: note.id)
            openWindow(for: note.id, isNewNote: false)
        }
    }

    private func validateAndFixFrame(for noteId: UUID) {
        guard let note = store.note(for: noteId) else { return }
        let frame = note.windowFrame

        // Check if the note's frame overlaps with any connected screen
        let screens = NSScreen.screens
        let isOnScreen = screens.contains { screen in
            screen.visibleFrame.intersects(frame)
        }

        if !isOnScreen, let mainScreen = NSScreen.main {
            // Move to center of main screen
            let screenFrame = mainScreen.visibleFrame
            let newOrigin = CGPoint(
                x: screenFrame.midX - frame.width / 2,
                y: screenFrame.midY - frame.height / 2
            )
            let fixedFrame = CGRect(origin: newOrigin, size: frame.size)
            store.updateFrame(for: noteId, frame: fixedFrame)
        }
    }

    func isWindowOpen(for noteId: UUID) -> Bool {
        windowControllers[noteId]?.window?.isVisible == true
    }
}
