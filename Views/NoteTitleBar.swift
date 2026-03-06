import SwiftUI

struct NoteTitleBar: View {
    let noteId: UUID
    @ObservedObject var store: NoteStore
    let onClose: () -> Void
    let onDelete: () -> Void
    let onToggleCollapse: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovering = false

    private var note: Note? {
        store.note(for: noteId)
    }

    private var firstLine: String {
        guard let note = note else { return "" }
        let trimmed = note.content.trimmingCharacters(in: .whitespacesAndNewlines)
        if let newlineIndex = trimmed.firstIndex(of: "\n") {
            return String(trimmed[..<newlineIndex])
        }
        return trimmed
    }

    var body: some View {
        if let note = note {
            WindowDragView(onDoubleClick: {
                onToggleCollapse()
            }) {
                HStack(spacing: 6) {
                    // Collapse/expand button - always visible
                    Button {
                        onToggleCollapse()
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

                    // Controls that reveal on hover
                    if isHovering || note.isCollapsed {
                        // Pin indicator
                        if note.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 9))
                                .foregroundColor(note.color.text(for: colorScheme).opacity(0.5))
                                .transition(.opacity)
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
                        .transition(.opacity)

                        // Close button
                        Button {
                            onClose()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(note.color.text(for: colorScheme).opacity(0.5))
                                .frame(width: 16, height: 16)
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity)
                    } else if note.isPinned {
                        // Show pin indicator even when not hovering
                        Image(systemName: "pin.fill")
                            .font(.system(size: 9))
                            .foregroundColor(note.color.text(for: colorScheme).opacity(0.3))
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(height: 24)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovering = hovering
                }
            }
        }
    }

    @ViewBuilder
    private func settingsMenu(note: Note) -> some View {
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

        // Export
        Menu("Export") {
            Button("As Plain Text (.txt)") {
                NoteExporter.export(note, format: .txt)
            }
            Button("As Markdown (.md)") {
                NoteExporter.export(note, format: .md)
            }
        }

        // Share
        Button("Share...") {
            if let window = NSApp.keyWindow, let contentView = window.contentView {
                NoteExporter.share(note, from: contentView)
            }
        }

        Divider()

        // Collapse toggle
        Button {
            onToggleCollapse()
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
