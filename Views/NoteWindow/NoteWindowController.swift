import AppKit
import SwiftUI
import Combine

final class NoteWindowController: NSWindowController, NSWindowDelegate {
    private let noteId: UUID
    private let store: NoteStore
    private var cancellables = Set<AnyCancellable>()
    private var frameDebounceTask: Task<Void, Never>?
    private let isNewNote: Bool
    private var expandedHeight: CGFloat = 250
    private var isHandlingCollapseChange: Bool = false

    init(noteId: UUID, store: NoteStore, isNewNote: Bool = false) {
        self.noteId = noteId
        self.store = store
        self.isNewNote = isNewNote

        let note = store.note(for: noteId)
        let frame = note?.windowFrame ?? CGRect(x: 0, y: 0, width: 220, height: 250)
        self.expandedHeight = frame.height

        let panel = NotePanel(noteId: noteId, frame: frame)

        super.init(window: panel)

        panel.delegate = self

        let contentView = NoteEditorView(
            noteId: noteId,
            store: store,
            onClose: { [weak self] in
                self?.close()
            },
            onDelete: { [weak self] in
                self?.deleteNote()
            },
            onCollapseChange: { [weak self] isCollapsed in
                self?.handleCollapseChange(isCollapsed: isCollapsed)
            }
        )

        panel.contentView = NSHostingView(rootView: contentView)

        // Center new notes on screen
        if isNewNote {
            panel.centerOnScreen()
            Task { @MainActor in
                store.updateFrame(for: noteId, frame: panel.frame)
            }
        }

        observeNoteChanges()
        updateFloatingLevel()

        // Handle initial collapsed state
        if let note = note, note.isCollapsed {
            // Defer to allow window setup to complete
            DispatchQueue.main.async { [weak self] in
                self?.handleCollapseChange(isCollapsed: true)
            }
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func observeNoteChanges() {
        store.$notes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notes in
                guard let self = self,
                      notes.first(where: { $0.id == self.noteId }) != nil else { return }

                self.updateFloatingLevel()
            }
            .store(in: &cancellables)
    }

    private func handleCollapseChange(isCollapsed: Bool) {
        guard let panel = window as? NotePanel else { return }

        let handleHeight: CGFloat = 24
        let currentFrame = panel.frame

        // Prevent windowDidResize from interfering
        isHandlingCollapseChange = true

        let targetFrame: NSRect
        if isCollapsed {
            // Only save current height if the window is actually expanded
            if currentFrame.height > handleHeight {
                expandedHeight = currentFrame.height
            }
            targetFrame = NSRect(
                x: currentFrame.origin.x,
                y: currentFrame.maxY - handleHeight,
                width: currentFrame.width,
                height: handleHeight
            )
        } else {
            targetFrame = NSRect(
                x: currentFrame.origin.x,
                y: currentFrame.maxY - expandedHeight,
                width: currentFrame.width,
                height: expandedHeight
            )
        }

        // Smooth 200ms animation
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(targetFrame, display: true)
        }, completionHandler: { [weak self] in
            self?.isHandlingCollapseChange = false
        })
    }

    private func updateFloatingLevel() {
        guard let panel = window as? NotePanel,
              let note = store.note(for: noteId) else { return }
        panel.updateFloatingLevel(isPinned: note.isPinned)
    }

    func showWindow() {
        window?.makeKeyAndOrderFront(nil)
    }

    func windowDidMove(_ notification: Notification) {
        scheduleFrameUpdate()
    }

    func windowDidResize(_ notification: Notification) {
        // Don't interfere during programmatic collapse/expand
        guard !isHandlingCollapseChange else { return }
        guard let note = store.note(for: noteId), !note.isCollapsed else { return }
        if let frame = window?.frame {
            expandedHeight = frame.height
        }
        scheduleFrameUpdate()
    }

    private func scheduleFrameUpdate() {
        guard let note = store.note(for: noteId), !note.isCollapsed,
              let frame = window?.frame else { return }

        frameDebounceTask?.cancel()
        frameDebounceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000)
            guard !Task.isCancelled else { return }
            store.updateFrame(for: noteId, frame: frame)
        }
    }

    func windowWillClose(_ notification: Notification) {
        if let frame = window?.frame, let note = store.note(for: noteId), !note.isCollapsed {
            store.updateFrame(for: noteId, frame: frame)
        }
        WindowManager.shared.removeWindow(for: noteId)
    }

    private func deleteNote() {
        store.deleteNote(id: noteId)
        close()
    }
}
