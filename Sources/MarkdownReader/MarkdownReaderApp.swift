import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}

@main
struct MarkdownReaderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1000, height: 900)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open...") {
                    appState.showFileImporter = true
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Quick Open") {
                    appState.showQuickOpen.toggle()
                }
                .keyboardShortcut("p", modifiers: .command)

                Divider()

                Button("Add Workspace Folder...") {
                    appState.showFolderImporter = true
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])

                if !appState.workspaceManager.folders.isEmpty {
                    Divider()
                    Button("Rescan Workspaces") {
                        appState.workspaceManager.rescanAll()
                    }
                }
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
