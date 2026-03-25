import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
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
                            ForEach(files) { file in
                                Button(action: { appState.loadWorkspaceFile(file) }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "doc.text")
                                            .foregroundStyle(.secondary)
                                            .font(.system(size: 12))
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(file.name)
                                                .font(.system(size: 13))
                                                .foregroundStyle(.primary)
                                                .lineLimit(1)
                                            if file.relativePath != file.name + ".md" {
                                                Text(file.relativePath)
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(.tertiary)
                                                    .lineLimit(1)
                                            }
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
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
