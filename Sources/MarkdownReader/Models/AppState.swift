import SwiftUI

@Observable
final class AppState {
    var markdownContent: String = ""
    var fileURL: URL?
    var fileName: String = "MarkdownReader"
    var showFileImporter: Bool = false
    var fontSize: CGFloat = 17

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
