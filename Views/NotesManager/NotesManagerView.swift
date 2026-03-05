import SwiftUI

struct NotesManagerView: View {
    @ObservedObject var store: NoteStore

    private let columns = [
        GridItem(.adaptive(minimum: 180, maximum: 220), spacing: 12)
    ]

    private var sortedNotes: [Note] {
        store.notes.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned
            }
            return lhs.modifiedAt > rhs.modifiedAt
        }
    }

    var body: some View {
        Group {
            if store.notes.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(sortedNotes) { note in
                            ManagerNoteCardView(note: note)
                                .onTapGesture(count: 2) {
                                    WindowManager.shared.openWindow(for: note.id)
                                }
                                .contextMenu {
                                    colorMenu(for: note)
                                    Divider()
                                    Button(note.isPinned ? "Unpin" : "Pin to Top") {
                                        store.togglePinned(for: note.id)
                                    }
                                    Divider()
                                    Button("Delete", role: .destructive) {
                                        WindowManager.shared.closeWindow(for: note.id)
                                        withAnimation {
                                            store.deleteNote(id: note.id)
                                        }
                                    }
                                }
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
        .background(Color(nsColor: .windowBackgroundColor))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    WindowManager.shared.createAndOpenNewNote()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "note.text")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No Notes Yet")
                .font(.title2)
                .fontWeight(.medium)
            Text("Click + to create your first note")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func colorMenu(for note: Note) -> some View {
        Menu("Color") {
            ForEach(NoteColor.allCases) { color in
                Button {
                    store.updateColor(for: note.id, color: color)
                } label: {
                    Label(color.displayName, systemImage: color == note.color ? "checkmark.circle.fill" : "circle.fill")
                }
            }
        }
    }
}
