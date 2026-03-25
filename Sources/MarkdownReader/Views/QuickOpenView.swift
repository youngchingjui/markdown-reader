import SwiftUI

struct QuickOpenView: View {
    @Environment(AppState.self) private var appState
    @State private var searchText: String = ""
    @State private var selectedIndex: Int = 0
    @FocusState private var isSearchFocused: Bool

    var filteredFiles: [MarkdownFile] {
        let files = appState.workspaceManager.markdownFiles
        if searchText.isEmpty { return files }

        let query = searchText.lowercased()
        return files.filter { file in
            fuzzyMatch(query: query, target: file.relativePath.lowercased())
        }.sorted { a, b in
            // Prefer matches where filename starts with query
            let aName = a.name.lowercased()
            let bName = b.name.lowercased()
            let aStarts = aName.hasPrefix(query)
            let bStarts = bName.hasPrefix(query)
            if aStarts != bStarts { return aStarts }
            return a.relativePath < b.relativePath
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 16))
                TextField("Search markdown files...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .focused($isSearchFocused)
                    .onSubmit { openSelected() }
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // Results list
            if appState.workspaceManager.folders.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text("No workspaces connected")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Add a folder first via File > Add Workspace Folder")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else if filteredFiles.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Text("No matching files")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(filteredFiles.enumerated()), id: \.element.id) { index, file in
                                QuickOpenRow(
                                    file: file,
                                    folderName: appState.workspaceManager.folders.first { $0.id == file.workspaceFolderID }?.name ?? "",
                                    isSelected: index == selectedIndex
                                )
                                .id(index)
                                .onTapGesture { openFile(file) }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onChange(of: selectedIndex) { _, newValue in
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
        }
        .frame(width: 600, height: 400)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        .onAppear {
            isSearchFocused = true
            selectedIndex = 0
        }
        .onChange(of: searchText) { _, _ in
            selectedIndex = 0
        }
        .onKeyPress(.upArrow) {
            if selectedIndex > 0 { selectedIndex -= 1 }
            return .handled
        }
        .onKeyPress(.downArrow) {
            if selectedIndex < filteredFiles.count - 1 { selectedIndex += 1 }
            return .handled
        }
        .onKeyPress(.escape) {
            appState.showQuickOpen = false
            return .handled
        }
    }

    private func openSelected() {
        guard !filteredFiles.isEmpty, selectedIndex < filteredFiles.count else { return }
        openFile(filteredFiles[selectedIndex])
    }

    private func openFile(_ file: MarkdownFile) {
        appState.loadWorkspaceFile(file)
        appState.showQuickOpen = false
    }

    private func fuzzyMatch(query: String, target: String) -> Bool {
        var queryIndex = query.startIndex
        var targetIndex = target.startIndex

        while queryIndex < query.endIndex && targetIndex < target.endIndex {
            if query[queryIndex] == target[targetIndex] {
                queryIndex = query.index(after: queryIndex)
            }
            targetIndex = target.index(after: targetIndex)
        }
        return queryIndex == query.endIndex
    }
}

struct QuickOpenRow: View {
    let file: MarkdownFile
    let folderName: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "doc.text")
                .foregroundStyle(.secondary)
                .font(.system(size: 14))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(file.relativePath)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Spacer()

            Text(folderName)
                .font(.system(size: 11))
                .foregroundStyle(.quaternary)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        .contentShape(Rectangle())
    }
}
