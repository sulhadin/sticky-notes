import SwiftUI

struct NoteEditorView: View {
    let noteId: UUID
    @ObservedObject var store: NoteStore
    let onClose: () -> Void
    let onDelete: () -> Void
    var onCollapseChange: ((Bool) -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @State private var content: String = ""
    @State private var showingCloseConfirmation = false

    private var note: StickyNote? {
        store.note(for: noteId)
    }

    var body: some View {
        if let note = note {
            VStack(spacing: 0) {
                // Draggable handle area at top - double click to collapse
                WindowDragView(onDoubleClick: {
                    toggleCollapse()
                }) {
                    dragHandleContent(note: note)
                }
                .frame(height: 24)

                // Content area
                if !note.isCollapsed {
                    PlainTextEditor(
                        text: $content,
                        textColor: note.color.text(for: colorScheme).nsColor,
                        backgroundColor: note.color.background(for: colorScheme).nsColor,
                        font: .systemFont(ofSize: note.fontSize)
                    )
                }
            }
            .background(
                VisualEffectView(
                    material: .hudWindow,
                    blendingMode: .behindWindow,
                    tintColor: note.color.background(for: colorScheme).nsColor,
                    tintOpacity: 0.87
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
                store.updateContent(for: noteId, content: newValue)
            }
            .onChange(of: note.content) { newValue in
                if content != newValue {
                    content = newValue
                }
            }
            .alert("Close Note?", isPresented: $showingCloseConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Close", role: .destructive) {
                    onClose()
                }
            } message: {
                Text("This note has content. Are you sure you want to close it?")
            }
        }
    }

    private var firstLine: String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if let newlineIndex = trimmed.firstIndex(of: "\n") {
            return String(trimmed[..<newlineIndex])
        }
        return trimmed
    }

    @ViewBuilder
    private func dragHandleContent(note: StickyNote) -> some View {
        HStack(spacing: 6) {
            // Collapse/expand button
            Button {
                toggleCollapse()
            } label: {
                Image(systemName: note.isCollapsed ? "chevron.down" : "minus")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(note.color.text(for: colorScheme).opacity(0.4))
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)

            // Show first line when collapsed
            if note.isCollapsed && !firstLine.isEmpty {
                Text(firstLine)
                    .font(.system(size: 11))
                    .foregroundColor(note.color.text(for: colorScheme).opacity(0.7))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer()

            // Pin indicator
            if note.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 9))
                    .foregroundColor(note.color.text(for: colorScheme).opacity(0.5))
            }

            // Settings menu
            Menu {
                settingsMenu(note: note)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(note.color.text(for: colorScheme).opacity(0.5))
                    .frame(width: 20, height: 16)
            }
            .buttonStyle(.plain)
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)

            // Close button
            Button {
                handleClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(note.color.text(for: colorScheme).opacity(0.5))
                    .frame(width: 16, height: 16)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func handleClose() {
        if let note = note, !note.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showingCloseConfirmation = true
        } else {
            onClose()
        }
    }

    private func toggleCollapse() {
        guard let note = note else { return }
        let newCollapsedState = !note.isCollapsed
        // Notify window controller first so it can resize the window
        onCollapseChange?(newCollapsedState)
        // Then update the store
        store.toggleCollapsed(for: noteId)
    }

    @ViewBuilder
    private func settingsMenu(note: StickyNote) -> some View {
        // Colors
        Menu("Color") {
            ForEach(NoteColor.allCases) { noteColor in
                Button {
                    store.updateColor(for: noteId, color: noteColor)
                } label: {
                    HStack {
                        Circle()
                            .fill(noteColor.backgroundColor)
                            .frame(width: 12, height: 12)
                        Text(noteColor.displayName)
                        if noteColor == note.color {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }

        // Text Size
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

        // Collapse toggle
        Button {
            toggleCollapse()
        } label: {
            Text(note.isCollapsed ? "Expand" : "Collapse")
        }

        // Pin toggle
        Button {
            store.togglePinned(for: noteId)
        } label: {
            HStack {
                Text(note.isPinned ? "Unpin from Top" : "Pin to Top")
                if note.isPinned {
                    Image(systemName: "checkmark")
                }
            }
        }

        Divider()

        // Delete
        Button(role: .destructive) {
            onDelete()
        } label: {
            Text("Delete Note")
        }
    }
}
