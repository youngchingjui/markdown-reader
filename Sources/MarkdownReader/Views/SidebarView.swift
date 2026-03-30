import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState

        List {
            if appState.workspaceManager.folders.isEmpty {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary)
                        Text("Add a workspace folder to browse markdown files")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Add Folder...") {
                            appState.showFolderImporter = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            } else {
                ForEach(appState.workspaceManager.folders) { folder in
                    Section(header: folderHeader(folder)) {
                        let files = appState.workspaceManager.markdownFiles.filter {
                            $0.workspaceFolderID == folder.id
                        }
                        if files.isEmpty {
                            Text("No markdown files found")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        } else {
                            let tree = buildFileTree(from: files)
                            ForEach(tree) { node in
                                FileTreeNodeView(node: node, appState: appState)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
        .safeAreaInset(edge: .bottom) {
            Button(action: { appState.showFolderImporter = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                    Text("Add Folder")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .background(.bar)
        }
        .fileImporter(
            isPresented: $state.showFolderImporter,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    appState.workspaceManager.addFolder(url: url)
                }
            case .failure:
                break
            }
        }
    }

    private func folderHeader(_ folder: WorkspaceFolder) -> some View {
        HStack {
            Image(systemName: "folder.fill")
                .foregroundStyle(.blue)
                .font(.system(size: 11))
            Text(folder.name)
                .font(.system(size: 12, weight: .semibold))
            Spacer()
            Button(action: { appState.workspaceManager.removeFolder(folder) }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.tertiary)
                    .font(.system(size: 11))
            }
            .buttonStyle(.plain)
            .help("Remove workspace")
        }
    }
}

// MARK: - File Tree

struct FileTreeNode: Identifiable {
    let id = UUID()
    let name: String
    let file: MarkdownFile?       // nil for directories
    var children: [FileTreeNode]
}

private func buildFileTree(from files: [MarkdownFile]) -> [FileTreeNode] {
    var root: [String: FileTreeNode] = [:]
    var rootFiles: [FileTreeNode] = []

    for file in files {
        let components = file.relativePath.split(separator: "/").map(String.init)

        if components.count == 1 {
            // File at root level
            rootFiles.append(FileTreeNode(name: file.name, file: file, children: []))
        } else {
            // File in a subdirectory — build directory nodes
            let dirName = components.first!

            if root[dirName] == nil {
                root[dirName] = FileTreeNode(name: dirName, file: nil, children: [])
            }

            if components.count == 2 {
                root[dirName]!.children.append(
                    FileTreeNode(name: file.name, file: file, children: [])
                )
            } else {
                // Deeper nesting — group under "dir/subdir" label
                let subPath = components.dropFirst().dropLast().joined(separator: "/")
                let existingSubdirIndex = root[dirName]!.children.firstIndex {
                    $0.file == nil && $0.name == subPath
                }
                if let idx = existingSubdirIndex {
                    root[dirName]!.children[idx].children.append(
                        FileTreeNode(name: file.name, file: file, children: [])
                    )
                } else {
                    var subdirNode = FileTreeNode(name: subPath, file: nil, children: [])
                    subdirNode.children.append(
                        FileTreeNode(name: file.name, file: file, children: [])
                    )
                    root[dirName]!.children.append(subdirNode)
                }
            }
        }
    }

    // Sort: directories first, then files, both alphabetically
    let sortedDirs = root.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    let sortedFiles = rootFiles.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

    return sortedDirs + sortedFiles
}

struct FileTreeNodeView: View {
    let node: FileTreeNode
    let appState: AppState
    @State private var isExpanded = false

    var body: some View {
        if let file = node.file {
            // Leaf file
            Button(action: { appState.loadWorkspaceFile(file) }) {
                HStack(spacing: 6) {
                    Image(systemName: "doc.text")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))
                    Text(node.name)
                        .font(.system(size: 13))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
            }
            .buttonStyle(.plain)
        } else {
            // Directory node
            DisclosureGroup(isExpanded: $isExpanded) {
                ForEach(node.children) { child in
                    FileTreeNodeView(node: child, appState: appState)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isExpanded ? "folder.fill" : "folder")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))
                    Text(node.name)
                        .font(.system(size: 13))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
            }
        }
    }
}
