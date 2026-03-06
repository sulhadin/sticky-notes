import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = NoteStore.shared
    private let windowManager = WindowManager.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Show the manager window on launch — notes are opened individually from there
        Task { @MainActor in
            NotesManagerWindowController.shared.showManager()
        }

        registerGlobalHotkey()
    }

    private func registerGlobalHotkey() {
        let hotKeyFlags: NSEvent.ModifierFlags = [.control, .option]

        // Global monitor — fires when another app is frontmost
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.modifierFlags.intersection(.deviceIndependentFlagsMask) == hotKeyFlags,
                  event.charactersIgnoringModifiers == "n" else { return }
            Task { @MainActor in
                NSApplication.shared.activate(ignoringOtherApps: true)
                self?.windowManager.createAndOpenNewNote()
            }
        }

        // Local monitor — fires when this app is frontmost
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.modifierFlags.intersection(.deviceIndependentFlagsMask) == hotKeyFlags,
                  event.charactersIgnoringModifiers == "n" else { return event }
            Task { @MainActor in
                self?.windowManager.createAndOpenNewNote()
            }
            return nil
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
