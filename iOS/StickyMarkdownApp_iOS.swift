import SwiftUI

@main
struct StickyMarkdownApp_iOS: App {
    @StateObject private var store = NoteStore.shared

    var body: some Scene {
        WindowGroup {
            NoteGridView(store: store)
        }
    }
}
