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
        textView.isRichText = true
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

        // Enable find bar
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true

        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]

        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true

        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.insertionPointColor = textColor
        textView.textContainerInset = NSSize(width: 12, height: 12)

        // Set typing attributes (for newly typed text) — NOT textView.font/textColor
        textView.typingAttributes = [
            .font: font,
            .foregroundColor: textColor
        ]

        scrollView.documentView = textView

        let coordinator = context.coordinator
        coordinator.textView = textView
        coordinator.currentFont = font
        coordinator.currentTextColor = textColor
        coordinator.styler.baseFont = font
        coordinator.styler.baseTextColor = textColor

        // Set initial text and apply styles
        if !text.isEmpty {
            textView.string = text
            coordinator.applyMarkdownStyling()
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? PlainTextView else { return }
        let coordinator = context.coordinator

        // Prevent re-entrant updates from our own textDidChange
        guard !coordinator.isUpdatingBinding else { return }

        // Check if font or color changed (user changed note settings)
        let fontChanged = coordinator.currentFont != font
        let colorChanged = coordinator.currentTextColor != textColor

        if fontChanged || colorChanged {
            coordinator.currentFont = font
            coordinator.currentTextColor = textColor
            coordinator.styler.baseFont = font
            coordinator.styler.baseTextColor = textColor
            textView.insertionPointColor = textColor
            textView.typingAttributes = [
                .font: font,
                .foregroundColor: textColor
            ]
            // Re-apply styles with new font/color
            coordinator.applyMarkdownStyling()
        }

        // Only set text if it genuinely changed from an external source
        // (e.g. CloudKit sync, undo from NoteStore, etc.)
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
            coordinator.applyMarkdownStyling()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var text: Binding<String>
        weak var textView: PlainTextView?
        let styler = MarkdownStyler()
        var isUpdatingBinding = false
        var currentFont: NSFont = .systemFont(ofSize: 14)
        var currentTextColor: NSColor = .black

        init(text: Binding<String>) {
            self.text = text
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }

            // Update the SwiftUI binding, but flag to prevent re-entrant updateNSView
            isUpdatingBinding = true
            text.wrappedValue = textView.string
            isUpdatingBinding = false

            // Apply markdown styling synchronously
            applyMarkdownStyling()
        }

        func applyMarkdownStyling() {
            guard let textView = textView,
                  let textStorage = textView.textStorage else { return }

            let selectedRanges = textView.selectedRanges
            let clipView = textView.enclosingScrollView?.contentView
            let savedOrigin = clipView?.bounds.origin

            textStorage.beginEditing()
            styler.applyStyles(to: textStorage)
            textStorage.endEditing()

            textView.selectedRanges = selectedRanges

            // Restore scroll position to prevent jumping from font size changes,
            // then ensure the cursor remains visible.
            if let origin = savedOrigin {
                clipView?.setBoundsOrigin(origin)
            }
            textView.scrollRangeToVisible(textView.selectedRange())
        }
    }
}

final class PlainTextView: NSTextView {

    // Enable find bar support
    override func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
        if let action = item.action,
           action == #selector(performTextFinderAction(_:)) {
            return true
        }
        return super.validateUserInterfaceItem(item)
    }

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
