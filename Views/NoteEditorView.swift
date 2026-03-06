import SwiftUI

struct NoteEditorView: View {
    let noteId: UUID
    @ObservedObject var store: NoteStore
    let onClose: () -> Void
    let onDelete: () -> Void
    var onCollapseChange: ((Bool) -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @State private var content: String = ""

    private var note: Note? {
        store.note(for: noteId)
    }

    var body: some View {
        if let note = note {
            VStack(spacing: 0) {
                // Title bar with hover-reveal controls
                NoteTitleBar(
                    noteId: noteId,
                    store: store,
                    onClose: onClose,
                    onDelete: onDelete,
                    onToggleCollapse: { toggleCollapse() }
                )

                // Content area with animation
                if !note.isCollapsed {
                    PlainTextEditor(
                        text: $content,
                        textColor: note.color.text(for: colorScheme).nsColor,
                        backgroundColor: note.color.background(for: colorScheme).nsColor,
                        font: .systemFont(ofSize: note.fontSize)
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background(
                VisualEffectView(
                    material: .hudWindow,
                    blendingMode: .behindWindow,
                    tintColor: note.color.background(for: colorScheme).nsColor,
                    tintOpacity: 0.50
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(note.color.border(for: colorScheme), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
            .onAppear {
                content = note.content
            }
            .onChange(of: content) { newValue in
                Task {
                    guard store.note(for: noteId)?.content != newValue else { return }
                    store.updateContent(for: noteId, content: newValue)
                }
            }
            .onChange(of: note.content) { newValue in
                if content != newValue {
                    content = newValue
                }
            }
        }
    }

    private func toggleCollapse() {
        guard let note = note else { return }
        let newCollapsedState = !note.isCollapsed
        onCollapseChange?(newCollapsedState)
        store.toggleCollapsed(for: noteId)
    }
}
