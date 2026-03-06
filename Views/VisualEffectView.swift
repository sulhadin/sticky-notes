import SwiftUI
import AppKit

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    let tintColor: NSColor?
    let tintOpacity: CGFloat

    init(
        material: NSVisualEffectView.Material = .hudWindow,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        tintColor: NSColor? = nil,
        tintOpacity: CGFloat = 0.50
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.tintColor = tintColor
        self.tintOpacity = tintOpacity
    }

    func makeNSView(context: Context) -> TintedVisualEffectView {
        let view = TintedVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.updateTint(color: tintColor, opacity: tintOpacity)
        return view
    }

    func updateNSView(_ nsView: TintedVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.updateTint(color: tintColor, opacity: tintOpacity)
    }
}

class TintedVisualEffectView: NSVisualEffectView {
    private var tintView: NSView?

    func updateTint(color: NSColor?, opacity: CGFloat) {
        if let color = color {
            if tintView == nil {
                let view = NSView()
                view.wantsLayer = true
                view.autoresizingMask = [.width, .height]
                addSubview(view)
                tintView = view
            }
            tintView?.frame = bounds
            tintView?.layer?.backgroundColor = color.withAlphaComponent(opacity).cgColor
        } else {
            tintView?.removeFromSuperview()
            tintView = nil
        }
    }

    override func layout() {
        super.layout()
        tintView?.frame = bounds
    }
}
