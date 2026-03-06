import SwiftUI

@main
struct StickyMarkdownApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var store = NoteStore.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(store: store)
        } label: {
            Image(systemName: "square.stack")
        }
        .menuBarExtraStyle(.window)
    }
}
