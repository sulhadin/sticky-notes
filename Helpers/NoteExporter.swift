import AppKit

enum NoteExportFormat: String {
    case txt = "txt"
    case md = "md"

    var fileExtension: String { rawValue }

    var contentType: String {
        switch self {
        case .txt: return "public.plain-text"
        case .md: return "net.daringfireball.markdown"
        }
    }
}

enum NoteExporter {

    static func export(_ note: Note, format: NoteExportFormat) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(note.title).\(format.fileExtension)"
        panel.allowedContentTypes = [
            format == .md
                ? .init(filenameExtension: "md") ?? .plainText
                : .plainText
        ]
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try note.content.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            let alert = NSAlert(error: error)
            alert.runModal()
        }
    }

    static func share(_ note: Note, from view: NSView) {
        let items: [Any] = [note.content]
        let picker = NSSharingServicePicker(items: items)
        picker.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
    }
}
