import SwiftUI

@Observable
final class AppState {
    var markdownContent: String = ""
    var fileURL: URL?
    var fileName: String = "MarkdownReader"
    var showFileImporter: Bool = false
    var showFolderImporter: Bool = false
    var showQuickOpen: Bool = false
    var fontSize: CGFloat = 17

    let workspaceManager = WorkspaceManager()

    private let minFontSize: CGFloat = 12
    private let maxFontSize: CGFloat = 28

    func loadFile(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            markdownContent = try String(contentsOf: url, encoding: .utf8)
            fileURL = url
            fileName = url.deletingPathExtension().lastPathComponent
        } catch {
            markdownContent = "**Error:** Could not read file.\n\n`\(error.localizedDescription)`"
            fileName = "Error"
        }
    }

    func loadWorkspaceFile(_ file: MarkdownFile) {
        if let content = workspaceManager.loadFile(file) {
            markdownContent = content
            fileURL = file.url
            fileName = file.name
        }
    }

    func increaseFontSize() {
        fontSize = min(fontSize + 1, maxFontSize)
    }

    func decreaseFontSize() {
        fontSize = max(fontSize - 1, minFontSize)
    }

    func resetFontSize() {
        fontSize = 17
    }
}
