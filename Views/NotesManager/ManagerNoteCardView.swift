import SwiftUI

struct ManagerNoteCardView: View {
    let note: Note
    var searchText: String = ""
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Pin indicator
            if note.isPinned {
                HStack {
                    Spacer()
                    Image(systemName: "pin.fill")
                        .font(.system(size: 10))
                        .foregroundColor(note.color.text(for: colorScheme).opacity(0.5))
                }
            }

            // Note content preview
            if note.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Empty Note")
                    .font(.system(size: min(note.fontSize, 14)))
                    .foregroundColor(note.color.text(for: colorScheme).opacity(0.4))
                    .italic()
            } else {
                highlightedText(note.content, search: searchText)
                    .font(.system(size: min(note.fontSize, 14)))
                    .foregroundColor(note.color.text(for: colorScheme))
                    .lineLimit(8)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 0)

            // Timestamp
            HStack {
                Spacer()
                Text(note.modifiedAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(note.color.text(for: colorScheme).opacity(0.4))
            }
        }
        .padding(12)
        .frame(minHeight: 140)
        .background(note.color.background(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    isHovered
                        ? note.color.text(for: colorScheme).opacity(0.4)
                        : note.color.border(for: colorScheme),
                    lineWidth: isHovered ? 1.5 : 0.5
                )
        )
        .shadow(color: Color.black.opacity(isHovered ? 0.15 : 0.08), radius: isHovered ? 8 : 4, x: 0, y: 2)
        .scaleEffect(isHovered ? 1.03 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private func highlightedText(_ content: String, search: String) -> Text {
        guard !search.isEmpty else {
            return Text(content)
        }
        let lowered = content.lowercased()
        let query = search.lowercased()
        var result = Text("")
        var currentIndex = lowered.startIndex

        while let range = lowered.range(of: query, range: currentIndex..<lowered.endIndex) {
            if currentIndex < range.lowerBound {
                result = result + Text(content[currentIndex..<range.lowerBound])
            }
            result = result + Text(content[range])
                .bold()
                .underline()
                .foregroundColor(Color.yellow)
            currentIndex = range.upperBound
        }
        if currentIndex < lowered.endIndex {
            result = result + Text(content[currentIndex..<lowered.endIndex])
        }
        return result
    }
}
