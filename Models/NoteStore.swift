import Foundation
import Combine

@MainActor
final class NoteStore: ObservableObject {
    static let shared = NoteStore()

    @Published private(set) var notes: [StickyNote] = []

    private let persistenceManager = PersistenceManager.shared
    private var saveTask: Task<Void, Never>?

    private init() {
        loadNotes()
    }

    func loadNotes() {
        notes = persistenceManager.load()
    }

    func createNote(color: NoteColor = .silver, at position: CGPoint? = nil) -> StickyNote {
        var frame = CGRect(x: 100, y: 100, width: 250, height: 300)

        if let position = position {
            frame.origin = position
        } else {
            let offset = CGFloat(notes.count % 10) * 30
            frame.origin = CGPoint(x: 100 + offset, y: 100 + offset)
        }

        let note = StickyNote(
            content: "",
            color: color,
            windowFrame: frame
        )

        notes.append(note)
        scheduleSave()

        return note
    }

    func updateNote(_ note: StickyNote) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            var updatedNote = note
            updatedNote.modifiedAt = Date()
            notes[index] = updatedNote
            scheduleSave()
        }
    }

    func updateContent(for noteId: UUID, content: String) {
        if let index = notes.firstIndex(where: { $0.id == noteId }) {
            notes[index].content = content
            notes[index].modifiedAt = Date()
            scheduleSave()
        }
    }

    func updateColor(for noteId: UUID, color: NoteColor) {
        if let index = notes.firstIndex(where: { $0.id == noteId }) {
            notes[index].color = color
            notes[index].modifiedAt = Date()
            scheduleSave()
        }
    }

    func updateFrame(for noteId: UUID, frame: CGRect) {
        if let index = notes.firstIndex(where: { $0.id == noteId }) {
            notes[index].windowFrame = frame
            scheduleSave()
        }
    }

    func togglePinned(for noteId: UUID) {
        if let index = notes.firstIndex(where: { $0.id == noteId }) {
            notes[index].isPinned.toggle()
            scheduleSave()
        }
    }

    func toggleCollapsed(for noteId: UUID) {
        if let index = notes.firstIndex(where: { $0.id == noteId }) {
            notes[index].isCollapsed.toggle()
            scheduleSave()
        }
    }

    func updateFontSize(for noteId: UUID, fontSize: CGFloat) {
        if let index = notes.firstIndex(where: { $0.id == noteId }) {
            notes[index].fontSize = fontSize
            scheduleSave()
        }
    }

    func deleteNote(id: UUID) {
        notes.removeAll { $0.id == id }
        scheduleSave()
    }

    func note(for id: UUID) -> StickyNote? {
        notes.first { $0.id == id }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 500ms debounce
            guard !Task.isCancelled else { return }
            persistenceManager.save(notes)
        }
    }

    func forceSave() {
        saveTask?.cancel()
        persistenceManager.save(notes)
    }
}
