import SwiftUI

@main
struct MarkdownReaderApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 800, height: 900)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open...") {
                    appState.showFileImporter = true
                }
                .keyboardShortcut("o", modifiers: .command)
            }
            CommandGroup(after: .textFormatting) {
                Divider()
                Button("Increase Font Size") {
                    appState.increaseFontSize()
                }
                .keyboardShortcut("+", modifiers: .command)
                Button("Decrease Font Size") {
                    appState.decreaseFontSize()
                }
                .keyboardShortcut("-", modifiers: .command)
                Button("Reset Font Size") {
                    appState.resetFontSize()
                }
                .keyboardShortcut("0", modifiers: .command)
            }
        }
    }
}
