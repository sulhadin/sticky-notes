import AppKit
import SwiftUI

@MainActor
final class NotesManagerWindowController {
    static let shared = NotesManagerWindowController()
    private var window: NSWindow?

    private init() {}

    func showManager() {
        if let existing = window, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let managerView = NotesManagerView(store: NoteStore.shared)
        let hostingView = NSHostingView(rootView: managerView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 600, height: 500)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Sticky Markdown"
        window.contentView = hostingView
        window.minSize = NSSize(width: 400, height: 300)
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)

        // Add toolbar for the + button
        let toolbar = NSToolbar(identifier: "NotesManagerToolbar")
        toolbar.delegate = ToolbarDelegate.shared
        toolbar.displayMode = .iconOnly
        window.toolbar = toolbar

        NSApp.activate(ignoringOtherApps: true)

        self.window = window
    }
}

private final class ToolbarDelegate: NSObject, NSToolbarDelegate {
    static let shared = ToolbarDelegate()

    private let addNoteItemIdentifier = NSToolbarItem.Identifier("addNote")

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        if itemIdentifier == addNoteItemIdentifier {
            let item = NSToolbarItem(itemIdentifier: addNoteItemIdentifier)
            item.label = "New Note"
            item.image = NSImage(systemSymbolName: "plus", accessibilityDescription: "New Note")
            item.target = self
            item.action = #selector(addNote)
            return item
        }
        return nil
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.flexibleSpace, addNoteItemIdentifier]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [addNoteItemIdentifier, .flexibleSpace]
    }

    @objc private func addNote() {
        Task { @MainActor in
            WindowManager.shared.createAndOpenNewNote()
        }
    }
}
