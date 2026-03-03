import SwiftUI
import AppKit

struct PlainTextEditor: NSViewRepresentable {
    @Binding var text: String
    var textColor: NSColor
    var backgroundColor: NSColor
    var font: NSFont

    init(
        text: Binding<String>,
        textColor: NSColor = .black,
        backgroundColor: NSColor = .clear,
        font: NSFont = .systemFont(ofSize: 14)
    ) {
        self._text = text
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.font = font
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        let textView = PlainTextView()
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.usesFontPanel = false
        textView.usesRuler = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.isGrammarCheckingEnabled = false

        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]

        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true

        textView.font = font
        textView.textColor = textColor
        textView.backgroundColor = .clear
        textView.insertionPointColor = textColor
        textView.drawsBackground = false

        textView.textContainerInset = NSSize(width: 12, height: 12)

        scrollView.documentView = textView
        context.coordinator.textView = textView

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? PlainTextView else { return }

        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
        }

        textView.font = font
        textView.textColor = textColor
        textView.backgroundColor = .clear
        textView.insertionPointColor = textColor
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var text: Binding<String>
        weak var textView: PlainTextView?

        init(text: Binding<String>) {
            self.text = text
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text.wrappedValue = textView.string
        }
    }
}

final class PlainTextView: NSTextView {

    // Only restrict what we READ from pasteboard (paste), not what we WRITE (copy)
    override var readablePasteboardTypes: [NSPasteboard.PasteboardType] {
        return [.string]
    }

    // Override paste to always paste as plain text
    override func paste(_ sender: Any?) {
        pasteAsPlainText(sender)
    }

    override func pasteAsPlainText(_ sender: Any?) {
        guard let plainText = NSPasteboard.general.string(forType: .string) else { return }

        let insertionRange = selectedRange()
        if shouldChangeText(in: insertionRange, replacementString: plainText) {
            replaceCharacters(in: insertionRange, with: plainText)
            didChangeText()
        }
    }

    // Allow drag and drop but only accept plain text
    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard
        guard let plainText = pasteboard.string(forType: .string) else { return false }

        let dropPoint = convert(sender.draggingLocation, from: nil)
        let characterIndex = characterIndexForInsertion(at: dropPoint)

        let insertionRange = NSRange(location: characterIndex, length: 0)
        if shouldChangeText(in: insertionRange, replacementString: plainText) {
            replaceCharacters(in: insertionRange, with: plainText)
            didChangeText()
        }

        return true
    }

    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        let pasteboard = sender.draggingPasteboard
        if pasteboard.string(forType: .string) != nil {
            return .copy
        }
        return []
    }

    override func draggingUpdated(_ sender: any NSDraggingInfo) -> NSDragOperation {
        let pasteboard = sender.draggingPasteboard
        if pasteboard.string(forType: .string) != nil {
            return .copy
        }
        return []
    }

    override func prepareForDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        return true
    }
}
