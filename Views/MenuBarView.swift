import SwiftUI

struct MenuBarView: View {
    @ObservedObject var store: NoteStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            newNoteSection
            Divider()
            notesListSection
            Divider()
            actionsSection
            Divider()
            quitSection
        }
        .frame(width: 220)
    }

    private var newNoteSection: some View {
        Button {
            WindowManager.shared.createAndOpenNewNote()
        } label: {
            HStack {
                Image(systemName: "plus.square")
                Text("New Note")
                Spacer()
                Text("N")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .keyboardShortcut("n", modifiers: .command)
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var notesListSection: some View {
        Group {
            if store.notes.isEmpty {
                Text("No notes")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(store.notes.sorted(by: { $0.modifiedAt > $1.modifiedAt })) { note in
                            NoteListItem(note: note) {
                                WindowManager.shared.openWindow(for: note.id)
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
    }

    private var actionsSection: some View {
        VStack(spacing: 2) {
            Button {
                NotesManagerWindowController.shared.showManager()
            } label: {
                HStack {
                    Image(systemName: "square.grid.2x2")
                    Text("Notes Manager")
                    Spacer()
                    Text("M")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .keyboardShortcut("m", modifiers: [.command, .shift])
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)

            Button {
                WindowManager.shared.showAllNotes()
            } label: {
                HStack {
                    Image(systemName: "rectangle.stack")
                    Text("Show All Notes")
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)

            Button {
                WindowManager.shared.hideAllNotes()
            } label: {
                HStack {
                    Image(systemName: "eye.slash")
                    Text("Hide All Notes")
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
    }

    private var quitSection: some View {
        VStack(spacing: 2) {
            Button {
                showSettings()
            } label: {
                HStack {
                    Image(systemName: "gearshape")
                    Text("Settings...")
                    Spacer()
                    Text(",")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .keyboardShortcut(",", modifiers: .command)
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)

            Button {
                store.forceSave()
                NSApplication.shared.terminate(nil)
            } label: {
                HStack {
                    Image(systemName: "power")
                    Text("Quit Sticky Markdown")
                    Spacer()
                    Text("Q")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .keyboardShortcut("q", modifiers: .command)
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
    }

    private func showSettings() {
        SettingsWindowController.shared.showSettings()
    }
}

struct NoteListItem: View {
    let note: Note
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Circle()
                    .fill(note.color.backgroundColor)
                    .frame(width: 10, height: 10)

                Text(note.title)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()

                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
