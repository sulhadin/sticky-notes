import SwiftUI

struct NoteEditView: View {
    let noteId: UUID
    @ObservedObject var store: NoteStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var content: String = ""
    @FocusState private var isEditorFocused: Bool

    private var note: Note? {
        store.note(for: noteId)
    }

    var body: some View {
        NavigationStack {
            if let note = note {
                ZStack {
                    note.color.background(for: colorScheme)
                        .ignoresSafeArea()

                    MarkdownTextEditor(
                        text: $content,
                        textColor: UIColor(note.color.text(for: colorScheme)),
                        font: .systemFont(ofSize: note.fontSize)
                    )
                }
                .navigationTitle(note.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            noteMenu(note: note)
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                .onAppear {
                    content = note.content
                    isEditorFocused = true
                }
                .onChange(of: content) { newValue in
                    store.updateContent(for: noteId, content: newValue)
                }
                .onChange(of: note.content) { newValue in
                    if content != newValue {
                        content = newValue
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func noteMenu(note: Note) -> some View {
        // Color picker
        Menu("Color") {
            ForEach(NoteColor.allCases) { color in
                Button {
                    store.updateColor(for: noteId, color: color)
                } label: {
                    Label(color.displayName, systemImage: color == note.color ? "checkmark.circle.fill" : "circle.fill")
                }
            }
        }

        // Font size
        Menu("Text Size") {
            ForEach([12, 14, 16, 18, 20, 24], id: \.self) { size in
                Button {
                    store.updateFontSize(for: noteId, fontSize: CGFloat(size))
                } label: {
                    HStack {
                        Text("\(size) pt")
                        if Int(note.fontSize) == size {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }

        Divider()

        ShareLink(item: note.content, subject: Text(note.title))

        Divider()

        Button(note.isPinned ? "Unpin" : "Pin to Top") {
            store.togglePinned(for: noteId)
        }

        Divider()

        Button("Delete Note", role: .destructive) {
            store.deleteNote(id: noteId)
            dismiss()
        }
    }
}
