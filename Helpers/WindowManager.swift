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
            openWindow(for: note.id, isNewNote: false)
        }
    }

    func isWindowOpen(for noteId: UUID) -> Bool {
        windowControllers[noteId]?.window?.isVisible == true
    }
}
