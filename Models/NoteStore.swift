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

        if notes.isEmpty {
            seedDefaultNote()
        }

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

    func updateSortOrders(_ updates: [(UUID, Int)]) {
        for (noteId, order) in updates {
            if let index = notes.firstIndex(where: { $0.id == noteId }) {
                notes[index].sortOrder = order
            }
        }
        scheduleSave()
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

    private func seedDefaultNote() {
        let samples: [(NoteColor, String, CGRect)] = [
            (.silver, """
            # Meeting Notes

            **Project kickoff** — March 10

            - Define milestones
            - Assign team leads
            - Set up *weekly syncs*

            > Ship early, ship often.

            Next review: `Friday 3pm`
            """, CGRect(x: 80, y: 600, width: 270, height: 320)),

            (.spaceGray, """
            ## Shopping List

            - Espresso beans
            - Oat milk
            - ~~Butter~~ Already got it
            - Sourdough bread
            - Avocados
            - Fresh basil

            *Check farmer's market on Saturday*
            """, CGRect(x: 380, y: 620, width: 250, height: 300)),

            (.gold, """
            # Ideas

            **App features to explore:**

            1. Markdown support
            2. iCloud sync
            3. Color-coded notes
            4. Quick export

            > Simplicity is the ultimate sophistication.

            See [Apple HIG](https://developer.apple.com/design/) for guidance.
            """, CGRect(x: 660, y: 580, width: 270, height: 340)),

            (.roseGold, """
            ## Daily Journal

            *Today was a good day.*

            Finished the new **onboarding flow** and got positive feedback from the team.

            Things I'm grateful for:
            - Morning coffee
            - A productive afternoon
            - Good weather

            ```
            let mood = "happy"
            ```
            """, CGRect(x: 140, y: 200, width: 270, height: 340)),

            (.blue, """
            # Reading List

            - **Designing Data-Intensive Apps**
            - *The Pragmatic Programmer*
            - Clean Code
            - ~~Refactoring~~ Done!

            ## Currently Reading

            > Any fool can write code that a computer can understand. Good programmers write code that *humans* can understand.

            Chapter 12 — `Testing Strategies`
            """, CGRect(x: 440, y: 220, width: 270, height: 360)),

            (.purple, """
            ## Quick Recipe

            ### Avocado Toast

            **Ingredients:**
            - 1 ripe avocado
            - 2 slices sourdough
            - Lemon juice, salt, chili flakes

            **Steps:**
            1. Toast the bread
            2. Mash avocado with lemon & salt
            3. Spread and add chili flakes

            *Ready in 5 minutes!*
            """, CGRect(x: 740, y: 240, width: 260, height: 370)),
        ]

        for (color, content, frame) in samples {
            let note = Note(
                content: content,
                color: color,
                windowFrame: frame
            )
            let cdNote = CDNote(context: stack.viewContext)
            cdNote.update(from: note)
            notes.append(note)
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
