import SwiftUI
import AppKit

struct WindowDragView<Content: View>: NSViewRepresentable {
    let content: Content
    var onDoubleClick: (() -> Void)?

    init(onDoubleClick: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.onDoubleClick = onDoubleClick
    }

    func makeNSView(context: Context) -> DraggableHostingView<Content> {
        let view = DraggableHostingView(rootView: content)
        view.onDoubleClick = onDoubleClick
        return view
    }

    func updateNSView(_ nsView: DraggableHostingView<Content>, context: Context) {
        nsView.rootView = content
        nsView.onDoubleClick = onDoubleClick
    }
}

class DraggableHostingView<Content: View>: NSHostingView<Content> {
    private var initialMouseLocation: NSPoint?
    private var initialWindowOrigin: NSPoint?
    var onDoubleClick: (() -> Void)?

    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            onDoubleClick?()
        } else {
            // Store initial positions in screen coordinates
            initialMouseLocation = NSEvent.mouseLocation
            initialWindowOrigin = window?.frame.origin
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard let window = self.window,
              let initialMouse = initialMouseLocation,
              let initialOrigin = initialWindowOrigin else { return }

        // Calculate delta using screen coordinates
        let currentMouse = NSEvent.mouseLocation
        let deltaX = currentMouse.x - initialMouse.x
        let deltaY = currentMouse.y - initialMouse.y

        // Apply delta to original window position
        let newOrigin = NSPoint(
            x: initialOrigin.x + deltaX,
            y: initialOrigin.y + deltaY
        )

        window.setFrameOrigin(newOrigin)
    }

    override func mouseUp(with event: NSEvent) {
        initialMouseLocation = nil
        initialWindowOrigin = nil
    }
}
