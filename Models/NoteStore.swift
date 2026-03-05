import Foundation
import Combine
import CoreData

@MainActor
final class NoteStore: ObservableObject {
    static let shared = NoteStore()

    @Published private(set) var notes: [Note] = []

    private let stack = CoreDataStack.shared
    private var saveTask: Task<Void, Never>?

    private init() {
        MigrationManager.migrateJSONToCoreDataIfNeeded(context: stack.viewContext)
        fetchNotes()

        // Observe remote CloudKit changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(remoteStoreDidChange),
            name: .NSPersistentStoreRemoteChange,
            object: stack.container.persistentStoreCoordinator
        )
    }

    @objc private func remoteStoreDidChange(_ notification: Notification) {
        Task { @MainActor in
            fetchNotes()
        }
    }

    private func fetchNotes() {
        let request = CDNote.fetchRequest() as NSFetchRequest<CDNote>
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        do {
            let cdNotes = try stack.viewContext.fetch(request)
            notes = cdNotes.map { $0.toNote() }
        } catch {
            print("Failed to fetch notes: \(error)")
        }
    }

    func loadNotes() {
        fetchNotes()
    }

    func createNote(color: NoteColor = .silver, at position: CGPoint? = nil) -> Note {
        var frame = CGRect(x: 100, y: 100, width: 250, height: 300)

        if let position = position {
            frame.origin = position
        } else {
            let offset = CGFloat(notes.count % 10) * 30
            frame.origin = CGPoint(x: 100 + offset, y: 100 + offset)
        }

        let note = Note(
            content: "",
            color: color,
            windowFrame: frame
        )

        let cdNote = CDNote(context: stack.viewContext)
        cdNote.update(from: note)
        stack.save()

        notes.append(note)
        return note
    }

    func updateNote(_ note: Note) {
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
        deleteFromCoreData(id: id)
    }

    func note(for id: UUID) -> Note? {
        notes.first { $0.id == id }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 500ms debounce
            guard !Task.isCancelled else { return }
            persistAllNotes()
        }
    }

    func forceSave() {
        saveTask?.cancel()
        persistAllNotes()
    }

    private func persistAllNotes() {
        let context = stack.viewContext

        // Fetch all existing CD notes keyed by id
        let request = CDNote.fetchRequest() as NSFetchRequest<CDNote>
        guard let existing = try? context.fetch(request) else { return }
        var cdMap = [UUID: CDNote]()
        for cd in existing {
            if let uid = cd.id {
                cdMap[uid] = cd
            }
        }

        let currentIds = Set(notes.map(\.id))

        // Update or insert
        for note in notes {
            if let cdNote = cdMap[note.id] {
                cdNote.update(from: note)
            } else {
                let cdNote = CDNote(context: context)
                cdNote.update(from: note)
            }
        }

        // Delete removed notes
        for (uid, cdNote) in cdMap where !currentIds.contains(uid) {
            context.delete(cdNote)
        }

        stack.save()
    }

    private func deleteFromCoreData(id: UUID) {
        let context = stack.viewContext
        let request = CDNote.fetchRequest() as NSFetchRequest<CDNote>
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        if let results = try? context.fetch(request) {
            for obj in results {
                context.delete(obj)
            }
            stack.save()
        }
    }
}
