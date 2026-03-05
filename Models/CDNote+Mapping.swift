import CoreData
import CoreGraphics

extension CDNote {

    func toNote() -> Note {
        Note(
            id: id ?? UUID(),
            content: content ?? "",
            color: NoteColor(rawValue: colorRawValue ?? "silver") ?? .silver,
            isPinned: isPinned,
            isCollapsed: isCollapsed,
            fontSize: fontSize,
            windowFrame: CGRect(
                x: windowFrameX,
                y: windowFrameY,
                width: windowFrameWidth,
                height: windowFrameHeight
            ),
            createdAt: createdAt ?? Date(),
            modifiedAt: modifiedAt ?? Date()
        )
    }

    func update(from note: Note) {
        id = note.id
        content = note.content
        colorRawValue = note.color.rawValue
        isPinned = note.isPinned
        isCollapsed = note.isCollapsed
        fontSize = note.fontSize
        windowFrameX = note.windowFrame.origin.x
        windowFrameY = note.windowFrame.origin.y
        windowFrameWidth = note.windowFrame.size.width
        windowFrameHeight = note.windowFrame.size.height
        createdAt = note.createdAt
        modifiedAt = note.modifiedAt
    }
}
