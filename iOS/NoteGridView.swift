import SwiftUI

struct NoteGridView: View {
    @ObservedObject var store: NoteStore
    @State private var selectedNote: Note?
    @State private var showingSettings = false
    @State private var selectedColors: Set<NoteColor> = []
    @State private var searchText: String = ""

    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 12)
    ]

    private var filteredNotes: [Note] {
        var result = store.notes.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned
            }
            return lhs.modifiedAt > rhs.modifiedAt
        }
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
        NavigationStack {
            ScrollView {
                if store.notes.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 8) {
                        // Color filter bar
                        colorFilterBar
                            .padding(.horizontal)

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(filteredNotes) { note in
                                NoteCardView(note: note, searchText: searchText)
                                    .onTapGesture {
                                        selectedNote = note
                                    }
                                    .contextMenu {
                                        colorMenu(for: note)
                                        Divider()
                                        Button(note.isPinned ? "Unpin" : "Pin to Top") {
                                            store.togglePinned(for: note.id)
                                        }
                                        Divider()
                                        ShareLink(item: note.content, subject: Text(note.title))
                                        Divider()
                                        Button("Delete", role: .destructive) {
                                            withAnimation {
                                                store.deleteNote(id: note.id)
                                            }
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 4)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Sticky Markdown")
            .searchable(text: $searchText, prompt: "Search notes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        let note = store.createNote()
                        selectedNote = note
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(item: $selectedNote) { note in
                NoteEditView(noteId: note.id, store: store)
            }
            .sheet(isPresented: $showingSettings) {
                iOS_SettingsView()
            }
        }
    }

    private var colorFilterBar: some View {
        HStack(spacing: 8) {
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
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(Color.primary.opacity(0.2), lineWidth: 0.5)
                        )
                        .overlay(
                            selectedColors.contains(color)
                                ? Circle().stroke(Color.accentColor, lineWidth: 2.5)
                                : nil
                        )
                }
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
            Text("Tap + to create your first note")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
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
