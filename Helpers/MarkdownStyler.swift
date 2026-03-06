import AppKit
import Markdown

final class MarkdownStyler {

    var baseFont: NSFont = .systemFont(ofSize: 14)
    var baseTextColor: NSColor = .black

    /// Apply markdown styles to the given text storage. Call within beginEditing/endEditing.
    func applyStyles(to textStorage: NSTextStorage) {
        let length = textStorage.length
        guard length > 0 else { return }

        let text = textStorage.string
        let fullRange = NSRange(location: 0, length: length)

        // 1. Reset everything to base style
        textStorage.setAttributes([
            .font: baseFont,
            .foregroundColor: baseTextColor
        ], range: fullRange)

        // 2. Parse markdown AST
        let doc = Document(parsing: text)

        // 3. Build line-start byte offsets for SourceLocation -> NSRange conversion
        let lineStarts = Self.computeLineStarts(in: text)

        // 4. Walk AST and apply styles
        var walker = StyleWalker(
            text: text,
            storage: textStorage,
            lineStarts: lineStarts,
            baseFont: baseFont,
            baseTextColor: baseTextColor
        )
        walker.visit(doc)
    }

    /// Returns an array where element i is the UTF-8 byte offset of the start of line i (0-indexed).
    static func computeLineStarts(in text: String) -> [Int] {
        var starts: [Int] = [0]
        var offset = 0
        for byte in text.utf8 {
            offset += 1
            if byte == 0x0A { // '\n'
                starts.append(offset)
            }
        }
        return starts
    }
}

// MARK: - AST Walker

private struct StyleWalker: MarkupWalker {
    let text: String
    let storage: NSTextStorage
    let lineStarts: [Int]
    let baseFont: NSFont
    let baseTextColor: NSColor

    private var dimColor: NSColor { baseTextColor.withAlphaComponent(0.35) }

    // MARK: - SourceRange -> NSRange

    private func stringIndex(for loc: SourceLocation) -> String.Index? {
        let lineIdx = loc.line - 1
        guard lineIdx >= 0, lineIdx < lineStarts.count else { return nil }
        let byteOffset = lineStarts[lineIdx] + (loc.column - 1)
        let utf8 = text.utf8
        guard byteOffset >= 0, byteOffset <= utf8.count else { return nil }
        return utf8.index(utf8.startIndex, offsetBy: byteOffset)
    }

    private func nsRange(for sr: SourceRange) -> NSRange? {
        guard let s = stringIndex(for: sr.lowerBound),
              let e = stringIndex(for: sr.upperBound),
              s <= e else { return nil }
        return NSRange(s..<e, in: text)
    }

    private func nsRange(from: SourceLocation, to: SourceLocation) -> NSRange? {
        guard let s = stringIndex(for: from),
              let e = stringIndex(for: to),
              s < e else { return nil }
        return NSRange(s..<e, in: text)
    }

    // MARK: - Helpers

    /// Range of the children content (first child start to last child end), excluding markers.
    private func contentRange(of node: some Markup) -> NSRange? {
        let kids = Array(node.children)
        guard let first = kids.first(where: { $0.range != nil })?.range,
              let last = kids.last(where: { $0.range != nil })?.range else { return nil }
        return nsRange(from: first.lowerBound, to: last.upperBound)
    }

    /// Dim the gap between parent range and children range (the syntax markers).
    private func dimMarkers(of node: some Markup) {
        guard let sr = node.range else { return }
        let kids = Array(node.children)
        guard let first = kids.first(where: { $0.range != nil })?.range,
              let last = kids.last(where: { $0.range != nil })?.range else { return }
        if let open = nsRange(from: sr.lowerBound, to: first.lowerBound), open.length > 0 {
            storage.addAttribute(.foregroundColor, value: dimColor, range: open)
        }
        if let close = nsRange(from: last.upperBound, to: sr.upperBound), close.length > 0 {
            storage.addAttribute(.foregroundColor, value: dimColor, range: close)
        }
    }

    /// Add a font trait (bold/italic) to the existing font in a range, preserving other traits.
    private func addFontTrait(_ trait: NSFontTraitMask, in range: NSRange) {
        storage.enumerateAttribute(.font, in: range, options: []) { val, attrRange, _ in
            if let font = val as? NSFont {
                let converted = NSFontManager.shared.convert(font, toHaveTrait: trait)
                storage.addAttribute(.font, value: converted, range: attrRange)
            }
        }
    }

    // MARK: - Visitors

    mutating func visitHeading(_ heading: Heading) {
        guard let sr = heading.range, let nr = nsRange(for: sr) else {
            defaultVisit(heading)
            return
        }

        let size = baseFont.pointSize + CGFloat(7 - heading.level) * 2
        storage.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: size), range: nr)

        // Dim `# ` prefix
        if let first = heading.children.first(where: { $0.range != nil })?.range,
           let marker = nsRange(from: sr.lowerBound, to: first.lowerBound), marker.length > 0 {
            storage.addAttribute(.foregroundColor, value: dimColor, range: marker)
        }

        defaultVisit(heading)
    }

    mutating func visitStrong(_ strong: Strong) {
        if let r = contentRange(of: strong) { addFontTrait(.boldFontMask, in: r) }
        dimMarkers(of: strong)
        defaultVisit(strong)
    }

    mutating func visitEmphasis(_ emphasis: Emphasis) {
        if let r = contentRange(of: emphasis) { addFontTrait(.italicFontMask, in: r) }
        dimMarkers(of: emphasis)
        defaultVisit(emphasis)
    }

    mutating func visitStrikethrough(_ strikethrough: Strikethrough) {
        if let r = contentRange(of: strikethrough) {
            storage.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: r)
        }
        dimMarkers(of: strikethrough)
        defaultVisit(strikethrough)
    }

    mutating func visitInlineCode(_ inlineCode: InlineCode) {
        guard let sr = inlineCode.range, let nr = nsRange(for: sr) else { return }

        // Count leading backticks to determine marker length
        let src = (text as NSString).substring(with: nr)
        var markerLen = 0
        for ch in src { if ch == "`" { markerLen += 1 } else { break } }
        guard markerLen > 0, nr.length > 2 * markerLen else { return }

        let contentNR = NSRange(location: nr.location + markerLen, length: nr.length - 2 * markerLen)
        let codeFont = NSFont.monospacedSystemFont(ofSize: baseFont.pointSize - 1, weight: .regular)
        storage.addAttribute(.font, value: codeFont, range: contentNR)
        storage.addAttribute(.foregroundColor, value: baseTextColor.withAlphaComponent(0.85), range: contentNR)

        // Dim backtick markers
        storage.addAttribute(.foregroundColor, value: dimColor, range: NSRange(location: nr.location, length: markerLen))
        storage.addAttribute(.foregroundColor, value: dimColor, range: NSRange(location: nr.location + nr.length - markerLen, length: markerLen))
    }

    mutating func visitLink(_ link: Link) {
        if let r = contentRange(of: link) {
            storage.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: r)
            storage.addAttribute(.foregroundColor, value: NSColor.linkColor, range: r)
        }
        dimMarkers(of: link)
        defaultVisit(link)
    }

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) {
        guard let sr = blockQuote.range, let nr = nsRange(for: sr) else {
            defaultVisit(blockQuote)
            return
        }

        // Dim the entire blockquote text
        storage.addAttribute(.foregroundColor, value: baseTextColor.withAlphaComponent(0.6), range: nr)

        // Dim `> ` prefixes more aggressively on each line
        let nsText = text as NSString
        var scanLoc = nr.location
        let end = nr.location + nr.length
        while scanLoc < end {
            let lineRange = nsText.lineRange(for: NSRange(location: scanLoc, length: 0))
            if lineRange.location < end, nsText.character(at: lineRange.location) == 0x3E { // '>'
                var mLen = 1
                if lineRange.length > 1, lineRange.location + 1 < end,
                   nsText.character(at: lineRange.location + 1) == 0x20 { // ' '
                    mLen = 2
                }
                storage.addAttribute(.foregroundColor, value: dimColor, range: NSRange(location: lineRange.location, length: mLen))
            }
            let next = lineRange.location + lineRange.length
            if next <= scanLoc { break }
            scanLoc = next
        }

        defaultVisit(blockQuote)
    }

    mutating func visitListItem(_ listItem: ListItem) {
        guard let sr = listItem.range else {
            defaultVisit(listItem)
            return
        }

        // Dim the list marker (gap between list item start and first child)
        if let first = listItem.children.first(where: { $0.range != nil })?.range,
           let marker = nsRange(from: sr.lowerBound, to: first.lowerBound), marker.length > 0 {
            storage.addAttribute(.foregroundColor, value: dimColor, range: marker)
        }

        defaultVisit(listItem)
    }

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) {
        guard let sr = codeBlock.range, let nr = nsRange(for: sr) else { return }

        let codeFont = NSFont.monospacedSystemFont(ofSize: baseFont.pointSize - 1, weight: .regular)
        storage.addAttribute(.font, value: codeFont, range: nr)

        // Dim fence lines for fenced code blocks
        let src = (text as NSString).substring(with: nr)
        if src.hasPrefix("```") || src.hasPrefix("~~~") {
            // Opening fence (first line)
            if let nl = src.firstIndex(of: "\n") {
                let fenceLen = src.distance(from: src.startIndex, to: nl)
                if fenceLen > 0 {
                    storage.addAttribute(.foregroundColor, value: dimColor, range: NSRange(location: nr.location, length: fenceLen))
                }
            }
            // Closing fence (last line)
            if let nl = src.lastIndex(of: "\n") {
                let after = src.index(after: nl)
                if after < src.endIndex {
                    let closeLen = src.distance(from: after, to: src.endIndex)
                    if closeLen > 0 {
                        storage.addAttribute(.foregroundColor, value: dimColor, range: NSRange(location: nr.location + nr.length - closeLen, length: closeLen))
                    }
                }
            }
        }
    }
}
