import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("defaultFontSize") private var defaultFontSize: Double = 14
    @AppStorage("defaultFontFamily") private var defaultFontFamily: String = "System"
    @AppStorage("noteOpacity") private var noteOpacity: Double = 0.87
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false

    private let fontFamilies: [String] = {
        var families = ["System", "System Mono"]
        let systemFamilies = NSFontManager.shared.availableFontFamilies
            .filter { !$0.hasPrefix(".") }
            .sorted()
        families.append(contentsOf: systemFamilies)
        return families
    }()

    var body: some View {
        Form {
            Section("Font") {
                Picker("Font Family", selection: $defaultFontFamily) {
                    ForEach(fontFamilies, id: \.self) { family in
                        Text(family).tag(family)
                    }
                }

                HStack {
                    Text("Font Size")
                    Spacer()
                    Slider(value: $defaultFontSize, in: 10...32, step: 1)
                        .frame(width: 150)
                    Text("\(Int(defaultFontSize)) pt")
                        .frame(width: 40, alignment: .trailing)
                        .monospacedDigit()
                }
            }

            Section("Appearance") {
                HStack {
                    Text("Note Opacity")
                    Spacer()
                    Slider(value: $noteOpacity, in: 0.5...1.0, step: 0.05)
                        .frame(width: 150)
                    Text("\(Int(noteOpacity * 100))%")
                        .frame(width: 40, alignment: .trailing)
                        .monospacedDigit()
                }
            }

            Section("System") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        setLaunchAtLogin(newValue)
                    }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 280)
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
                launchAtLogin = !enabled
            }
        }
    }
}

@MainActor
final class SettingsWindowController {
    static let shared = SettingsWindowController()
    private var window: NSWindow?

    private init() {}

    func showSettings() {
        if let existing = window, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView()
        let hostingView = NSHostingView(rootView: settingsView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 400, height: 280)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 280),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Sticky Markdown Settings"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)

        self.window = window
    }
}
