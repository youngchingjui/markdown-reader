import SwiftUI
import Combine

@Observable
final class WorkspaceManager {
    var folders: [WorkspaceFolder] = []
    var markdownFiles: [MarkdownFile] = []
    var isScanning: Bool = false

    private let bookmarkKey = "workspaceFolderBookmarks"

    init() {
        loadBookmarks()
        scanAllFolders()
    }

    // MARK: - Folder Management

    func addFolder(url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        // Save bookmark for persistent access
        guard let bookmark = try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else { return }

        let folder = WorkspaceFolder(
            url: url,
            name: url.lastPathComponent,
            bookmark: bookmark
        )

        if !folders.contains(where: { $0.url == url }) {
            folders.append(folder)
            saveBookmarks()
            scanFolder(folder)
        }
    }

    func removeFolder(_ folder: WorkspaceFolder) {
        folders.removeAll { $0.id == folder.id }
        markdownFiles.removeAll { $0.workspaceFolderID == folder.id }
        saveBookmarks()
    }

    func rescanAll() {
        markdownFiles.removeAll()
        scanAllFolders()
    }

    // MARK: - Scanning

    private func scanAllFolders() {
        for folder in folders {
            scanFolder(folder)
        }
    }

    private func scanFolder(_ folder: WorkspaceFolder) {
        isScanning = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var stale = false
            guard let url = try? URL(
                resolvingBookmarkData: folder.bookmark,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &stale
            ) else {
                DispatchQueue.main.async { self?.isScanning = false }
                return
            }

            guard url.startAccessingSecurityScopedResource() else {
                DispatchQueue.main.async { self?.isScanning = false }
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            let files = self?.findMarkdownFiles(in: url, workspaceFolderID: folder.id) ?? []

            DispatchQueue.main.async {
                self?.markdownFiles.removeAll { $0.workspaceFolderID == folder.id }
                self?.markdownFiles.append(contentsOf: files)
                self?.markdownFiles.sort { $0.relativePath < $1.relativePath }
                self?.isScanning = false
            }
        }
    }

    private func findMarkdownFiles(in directory: URL, workspaceFolderID: UUID) -> [MarkdownFile] {
        var results: [MarkdownFile] = []
        let fm = FileManager.default
        let mdExtensions: Set<String> = ["md", "markdown", "mdown", "mkd"]

        guard let enumerator = fm.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey, .nameKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return results }

        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]),
                  resourceValues.isRegularFile == true else { continue }

            if mdExtensions.contains(fileURL.pathExtension.lowercased()) {
                let relativePath = fileURL.path.replacingOccurrences(
                    of: directory.path + "/",
                    with: ""
                )
                results.append(MarkdownFile(
                    url: fileURL,
                    name: fileURL.deletingPathExtension().lastPathComponent,
                    relativePath: relativePath,
                    workspaceFolderID: workspaceFolderID
                ))
            }
        }
        return results
    }

    // MARK: - File Loading

    func loadFile(_ file: MarkdownFile) -> String? {
        // Find the parent folder bookmark to get security-scoped access
        guard let folder = folders.first(where: { $0.id == file.workspaceFolderID }) else {
            return nil
        }

        var stale = false
        guard let folderURL = try? URL(
            resolvingBookmarkData: folder.bookmark,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &stale
        ) else { return nil }

        guard folderURL.startAccessingSecurityScopedResource() else { return nil }
        defer { folderURL.stopAccessingSecurityScopedResource() }

        return try? String(contentsOf: file.url, encoding: .utf8)
    }

    // MARK: - Bookmark Persistence

    private func saveBookmarks() {
        let data = folders.map { ["name": $0.name, "bookmark": $0.bookmark.base64EncodedString()] }
        UserDefaults.standard.set(data, forKey: bookmarkKey)
    }

    private func loadBookmarks() {
        guard let stored = UserDefaults.standard.array(forKey: bookmarkKey) as? [[String: String]] else { return }

        for entry in stored {
            guard let name = entry["name"],
                  let b64 = entry["bookmark"],
                  let bookmarkData = Data(base64Encoded: b64) else { continue }

            var stale = false
            guard let url = try? URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &stale
            ) else { continue }

            let folder = WorkspaceFolder(
                url: url,
                name: name,
                bookmark: stale ? (try? url.bookmarkData(
                    options: .withSecurityScope,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )) ?? bookmarkData : bookmarkData
            )
            folders.append(folder)
        }
    }
}

// MARK: - Data Models

struct WorkspaceFolder: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    let bookmark: Data
}

struct MarkdownFile: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    let relativePath: String
    let workspaceFolderID: UUID
}
