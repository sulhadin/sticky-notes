import SwiftUI

struct NoteGridView: View {
    @ObservedObject var store: NoteStore
    @State private var selectedNote: Note?
    @State private var showingSettings = false

    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                if store.notes.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(store.notes.sorted(by: { $0.modifiedAt > $1.modifiedAt })) { note in
                            NoteCardView(note: note)
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
                                    Button("Delete", role: .destructive) {
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
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Sticky Markdown")
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
