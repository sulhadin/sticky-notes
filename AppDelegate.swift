import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = NoteStore.shared
    private let windowManager = WindowManager.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Restore windows from previous session, or create first note if none exist
        Task { @MainActor in
            if store.notes.isEmpty {
                // Create a welcome note for first launch
                windowManager.createAndOpenNewNote(color: .silver)
            } else {
                windowManager.restoreWindows()
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep running as menu bar app
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Force save before quitting
        store.forceSave()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            // Show Notes Manager when clicking dock icon
            Task { @MainActor in
                NotesManagerWindowController.shared.showManager()
            }
        }
        return true
    }
}
