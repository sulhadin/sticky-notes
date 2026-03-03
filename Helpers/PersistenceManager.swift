import Foundation

final class PersistenceManager {
    static let shared = PersistenceManager()

    private let fileManager = FileManager.default
    private let fileName = "notes.json"

    private var applicationSupportDirectory: URL {
        let urls = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupportURL = urls[0].appendingPathComponent("StickyNote", isDirectory: true)

        if !fileManager.fileExists(atPath: appSupportURL.path) {
            try? fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        }

        return appSupportURL
    }

    private var notesFileURL: URL {
        applicationSupportDirectory.appendingPathComponent(fileName)
    }

    private init() {}

    func save(_ notes: [StickyNote]) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        do {
            let data = try encoder.encode(notes)
            try data.write(to: notesFileURL, options: .atomic)
        } catch {
            print("Failed to save notes: \(error)")
        }
    }

    func load() -> [StickyNote] {
        guard fileManager.fileExists(atPath: notesFileURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: notesFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([StickyNote].self, from: data)
        } catch {
            print("Failed to load notes: \(error)")
            return []
        }
    }
}
