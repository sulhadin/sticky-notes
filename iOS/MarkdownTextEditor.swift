import SwiftUI
import UIKit
import Markdown

struct MarkdownTextEditor: UIViewRepresentable {
    @Binding var text: String
    var textColor: UIColor
    var font: UIFont

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isSelectable = true
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        textView.autocapitalizationType = .sentences
        textView.autocorrectionType = .default
        textView.allowsEditingTextAttributes = false
        textView.typingAttributes = [
            .font: font,
            .foregroundColor: textColor
        ]

        let coordinator = context.coordinator
        coordinator.textView = textView
        coordinator.currentFont = font
        coordinator.currentTextColor = textColor

        if !text.isEmpty {
            textView.text = text
            coordinator.applyMarkdownStyling()
        }

        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        let coordinator = context.coordinator
        guard !coordinator.isUpdatingBinding else { return }

        let fontChanged = coordinator.currentFont != font
        let colorChanged = coordinator.currentTextColor != textColor

        if fontChanged || colorChanged {
            coordinator.currentFont = font
            coordinator.currentTextColor = textColor
            textView.typingAttributes = [
                .font: font,
                .foregroundColor: textColor
            ]
            coordinator.applyMarkdownStyling()
        }

        if textView.text != text {
            let selectedRange = textView.selectedRange
            textView.text = text
            textView.selectedRange = selectedRange
            coordinator.applyMarkdownStyling()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var text: Binding<String>
        weak var textView: UITextView?
        var isUpdatingBinding = false
        var currentFont: UIFont = .systemFont(ofSize: 14)
        var currentTextColor: UIColor = .black

        init(text: Binding<String>) {
            self.text = text
        }

        func textViewDidChange(_ textView: UITextView) {
            isUpdatingBinding = true
            text.wrappedValue = textView.text
            isUpdatingBinding = false
            applyMarkdownStyling()
        }

        func applyMarkdownStyling() {
            guard let textView = textView else { return }
            let text = textView.text ?? ""
            let length = (text as NSString).length
            guard length > 0 else { return }

            let selectedRange = textView.selectedRange

            let attributed = NSMutableAttributedString(string: text, attributes: [
                .font: currentFont,
                .foregroundColor: currentTextColor
            ])

            let doc = Document(parsing: text)
            let lineStarts = Self.computeLineStarts(in: text)

            var walker = StyleWalker(
                text: text,
                attributed: attributed,
                lineStarts: lineStarts,
                baseFont: currentFont,
                baseTextColor: currentTextColor
            )
            walker.visit(doc)

            let savedOffset = textView.contentOffset
            textView.attributedText = attributed
            textView.selectedRange = selectedRange
            textView.typingAttributes = [
                .font: currentFont,
                .foregroundColor: currentTextColor
            ]
            textView.setContentOffset(savedOffset, animated: false)
        }

        static func computeLineStarts(in text: String) -> [Int] {
            var starts: [Int] = [0]
            var offset = 0
            for byte in text.utf8 {
                offset += 1
                if byte == 0x0A {
                    starts.append(offset)
                }
            }
            return starts
        }
    }
}

// MARK: - AST Walker (iOS)

private struct StyleWalker: MarkupWalker {
    let text: String
    let attributed: NSMutableAttributedString
    let lineStarts: [Int]
    let baseFont: UIFont
    let baseTextColor: UIColor

    private var dimColor: UIColor { baseTextColor.withAlphaComponent(0.35) }

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

    private func contentRange(of node: some Markup) -> NSRange? {
        let kids = Array(node.children)
        guard let first = kids.first(where: { $0.range != nil })?.range,
              let last = kids.last(where: { $0.range != nil })?.range else { return nil }
        return nsRange(from: first.lowerBound, to: last.upperBound)
    }

    private func dimMarkers(of node: some Markup) {
        guard let sr = node.range else { return }
        let kids = Array(node.children)
        guard let first = kids.first(where: { $0.range != nil })?.range,
              let last = kids.last(where: { $0.range != nil })?.range else { return }
        if let open = nsRange(from: sr.lowerBound, to: first.lowerBound), open.length > 0 {
            attributed.addAttribute(.foregroundColor, value: dimColor, range: open)
        }
        if let close = nsRange(from: last.upperBound, to: sr.upperBound), close.length > 0 {
            attributed.addAttribute(.foregroundColor, value: dimColor, range: close)
        }
    }

    private func addFontTrait(_ trait: UIFontDescriptor.SymbolicTraits, in range: NSRange) {
        attributed.enumerateAttribute(.font, in: range, options: []) { val, attrRange, _ in
            if let font = val as? UIFont {
                var traits = font.fontDescriptor.symbolicTraits
                traits.insert(trait)
                if let desc = font.fontDescriptor.withSymbolicTraits(traits) {
                    attributed.addAttribute(.font, value: UIFont(descriptor: desc, size: font.pointSize), range: attrRange)
                }
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
        attributed.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: size), range: nr)

        if let first = heading.children.first(where: { $0.range != nil })?.range,
           let marker = nsRange(from: sr.lowerBound, to: first.lowerBound), marker.length > 0 {
            attributed.addAttribute(.foregroundColor, value: dimColor, range: marker)
        }

        defaultVisit(heading)
    }

    mutating func visitStrong(_ strong: Strong) {
        if let r = contentRange(of: strong) { addFontTrait(.traitBold, in: r) }
        dimMarkers(of: strong)
        defaultVisit(strong)
    }

    mutating func visitEmphasis(_ emphasis: Emphasis) {
        if let r = contentRange(of: emphasis) { addFontTrait(.traitItalic, in: r) }
        dimMarkers(of: emphasis)
        defaultVisit(emphasis)
    }

    mutating func visitStrikethrough(_ strikethrough: Strikethrough) {
        if let r = contentRange(of: strikethrough) {
            attributed.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: r)
        }
        dimMarkers(of: strikethrough)
        defaultVisit(strikethrough)
    }

    mutating func visitInlineCode(_ inlineCode: InlineCode) {
        guard let sr = inlineCode.range, let nr = nsRange(for: sr) else { return }

        let src = (text as NSString).substring(with: nr)
        var markerLen = 0
        for ch in src { if ch == "`" { markerLen += 1 } else { break } }
        guard markerLen > 0, nr.length > 2 * markerLen else { return }

        let contentNR = NSRange(location: nr.location + markerLen, length: nr.length - 2 * markerLen)
        let codeFont = UIFont.monospacedSystemFont(ofSize: baseFont.pointSize - 1, weight: .regular)
        attributed.addAttribute(.font, value: codeFont, range: contentNR)
        attributed.addAttribute(.foregroundColor, value: baseTextColor.withAlphaComponent(0.85), range: contentNR)

        attributed.addAttribute(.foregroundColor, value: dimColor, range: NSRange(location: nr.location, length: markerLen))
        attributed.addAttribute(.foregroundColor, value: dimColor, range: NSRange(location: nr.location + nr.length - markerLen, length: markerLen))
    }

    mutating func visitLink(_ link: Markdown.Link) {
        if let r = contentRange(of: link) {
            attributed.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: r)
            attributed.addAttribute(.foregroundColor, value: UIColor.link, range: r)
        }
        dimMarkers(of: link)
        defaultVisit(link)
    }

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) {
        guard let sr = blockQuote.range, let nr = nsRange(for: sr) else {
            defaultVisit(blockQuote)
            return
        }

        attributed.addAttribute(.foregroundColor, value: baseTextColor.withAlphaComponent(0.6), range: nr)

        let nsText = text as NSString
        var scanLoc = nr.location
        let end = nr.location + nr.length
        while scanLoc < end {
            let lineRange = nsText.lineRange(for: NSRange(location: scanLoc, length: 0))
            if lineRange.location < end, nsText.character(at: lineRange.location) == 0x3E {
                var mLen = 1
                if lineRange.length > 1, lineRange.location + 1 < end,
                   nsText.character(at: lineRange.location + 1) == 0x20 {
                    mLen = 2
                }
                attributed.addAttribute(.foregroundColor, value: dimColor, range: NSRange(location: lineRange.location, length: mLen))
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

        if let first = listItem.children.first(where: { $0.range != nil })?.range,
           let marker = nsRange(from: sr.lowerBound, to: first.lowerBound), marker.length > 0 {
            attributed.addAttribute(.foregroundColor, value: dimColor, range: marker)
        }

        defaultVisit(listItem)
    }

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) {
        guard let sr = codeBlock.range, let nr = nsRange(for: sr) else { return }

        let codeFont = UIFont.monospacedSystemFont(ofSize: baseFont.pointSize - 1, weight: .regular)
        attributed.addAttribute(.font, value: codeFont, range: nr)

        let src = (text as NSString).substring(with: nr)
        if src.hasPrefix("```") || src.hasPrefix("~~~") {
            if let nl = src.firstIndex(of: "\n") {
                let fenceLen = src.distance(from: src.startIndex, to: nl)
                if fenceLen > 0 {
                    attributed.addAttribute(.foregroundColor, value: dimColor, range: NSRange(location: nr.location, length: fenceLen))
                }
            }
            if let nl = src.lastIndex(of: "\n") {
                let after = src.index(after: nl)
                if after < src.endIndex {
                    let closeLen = src.distance(from: after, to: src.endIndex)
                    if closeLen > 0 {
                        attributed.addAttribute(.foregroundColor, value: dimColor, range: NSRange(location: nr.location + nr.length - closeLen, length: closeLen))
                    }
                }
            }
        }
    }
}
