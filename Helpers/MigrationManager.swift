import Foundation
import CoreData

final class MigrationManager {

    static func migrateJSONToCoreDataIfNeeded(context: NSManagedObjectContext) {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        // Check both old and new app support directory names for migration
        let oldDir = appSupport.appendingPathComponent("StickyNote", isDirectory: true)
        let newDir = appSupport.appendingPathComponent("StickyMarkdown", isDirectory: true)
        let notesDir = fileManager.fileExists(atPath: oldDir.appendingPathComponent("notes.json").path) ? oldDir : newDir
        let jsonURL = notesDir.appendingPathComponent("notes.json")

        guard fileManager.fileExists(atPath: jsonURL.path) else { return }

        do {
            let data = try Data(contentsOf: jsonURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let notes = try decoder.decode([Note].self, from: data)

            for note in notes {
                let cdNote = CDNote(context: context)
                cdNote.update(from: note)
            }

            try context.save()

            // Rename old file so migration doesn't run again
            let migratedURL = notesDir.appendingPathComponent("notes.json.migrated")
            try fileManager.moveItem(at: jsonURL, to: migratedURL)

            print("Migration complete: \(notes.count) notes migrated from JSON to Core Data")
        } catch {
            print("JSON to Core Data migration failed: \(error)")
        }
    }
}
