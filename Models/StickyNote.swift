import Foundation
import CoreGraphics

struct StickyNote: Codable, Identifiable, Equatable {
    let id: UUID
    var content: String
    var color: NoteColor
    var isPinned: Bool
    var isCollapsed: Bool
    var fontSize: CGFloat
    var windowFrame: CGRect
    var createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        content: String = "",
        color: NoteColor = .silver,
        isPinned: Bool = false,
        isCollapsed: Bool = false,
        fontSize: CGFloat = 14,
        windowFrame: CGRect = CGRect(x: 100, y: 100, width: 220, height: 250),
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.content = content
        self.color = color
        self.isPinned = isPinned
        self.isCollapsed = isCollapsed
        self.fontSize = fontSize
        self.windowFrame = windowFrame
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    var title: String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "Empty Note"
        }
        let firstLine = trimmed.components(separatedBy: .newlines).first ?? trimmed
        if firstLine.count > 30 {
            return String(firstLine.prefix(30)) + "..."
        }
        return firstLine
    }
}

extension CGRect: @retroactive Codable {
    enum CodingKeys: String, CodingKey {
        case x, y, width, height
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(CGFloat.self, forKey: .x)
        let y = try container.decode(CGFloat.self, forKey: .y)
        let width = try container.decode(CGFloat.self, forKey: .width)
        let height = try container.decode(CGFloat.self, forKey: .height)
        self.init(x: x, y: y, width: width, height: height)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(origin.x, forKey: .x)
        try container.encode(origin.y, forKey: .y)
        try container.encode(size.width, forKey: .width)
        try container.encode(size.height, forKey: .height)
    }
}
