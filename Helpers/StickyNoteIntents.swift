import AppIntents
import Foundation

struct CreateNoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Create Sticky Note"
    static var description: IntentDescription = "Creates a new sticky note in Sticky Markdown"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            WindowManager.shared.createAndOpenNewNote()
        }
        return .result()
    }
}

struct AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CreateNoteIntent(),
            phrases: [
                "Create a note in \(.applicationName)",
                "New note in \(.applicationName)",
                "New \(.applicationName) note"
            ],
            shortTitle: "New Note",
            systemImageName: "square.stack"
        )
    }
}
