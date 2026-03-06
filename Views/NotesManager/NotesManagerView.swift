import SwiftUI

struct NotesManagerView: View {
    @ObservedObject var store: NoteStore

    private let columns = [
        GridItem(.adaptive(minimum: 180, maximum: 220), spacing: 12)
    ]

    @State private var selectedColors: Set<NoteColor> = []
    @State private var searchText: String = ""

    private var sortedNotes: [Note] {
        store.notes.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned
            }
            return lhs.modifiedAt > rhs.modifiedAt
        }
    }

    private var filteredNotes: [Note] {
        var result = sortedNotes
        if !selectedColors.isEmpty {
            result = result.filter { selectedColors.contains($0.color) }
        }
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { $0.content.lowercased().contains(query) }
        }
        return result
    }

    var body: some View {
        Group {
            if store.notes.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search notes...", text: $searchText)
                            .textFieldStyle(.plain)
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Color filter bar
                    colorFilterBar
                        .padding(.horizontal)
                        .padding(.top, 8)

                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(filteredNotes) { note in
                            ManagerNoteCardView(note: note, searchText: searchText)
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
                                    Menu("Export") {
                                        Button("As Plain Text (.txt)") {
                                            NoteExporter.export(note, format: .txt)
                                        }
                                        Button("As Markdown (.md)") {
                                            NoteExporter.export(note, format: .md)
                                        }
                                    }
                                    Button("Share...") {
                                        if let window = NSApp.keyWindow, let contentView = window.contentView {
                                            NoteExporter.share(note, from: contentView)
                                        }
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

    private var colorFilterBar: some View {
        HStack(spacing: 6) {
            ForEach(NoteColor.allCases) { color in
                Button {
                    if selectedColors.contains(color) {
                        selectedColors.remove(color)
                    } else {
                        selectedColors.insert(color)
                    }
                } label: {
                    Circle()
                        .fill(color.backgroundColor)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(Color.primary.opacity(0.3), lineWidth: 0.5)
                        )
                        .overlay(
                            selectedColors.contains(color)
                                ? Circle().stroke(Color.accentColor, lineWidth: 2)
                                : nil
                        )
                }
                .buttonStyle(.plain)
            }
            if !selectedColors.isEmpty {
                Button("Clear") {
                    selectedColors.removeAll()
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            Spacer()
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

