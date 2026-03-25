import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState

        NavigationSplitView {
            SidebarView()
        } detail: {
            ZStack {
                if appState.markdownContent.isEmpty {
                    WelcomeView()
                } else {
                    MarkdownRenderView(
                        markdown: appState.markdownContent,
                        fontSize: appState.fontSize
                    )
                }

                // Quick Open overlay
                if appState.showQuickOpen {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture { appState.showQuickOpen = false }

                    VStack {
                        QuickOpenView()
                            .padding(.top, 60)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle(appState.fileName)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { appState.showFileImporter = true }) {
                    Label("Open", systemImage: "doc.text")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: { appState.showQuickOpen.toggle() }) {
                    Label("Quick Open", systemImage: "magnifyingglass")
                }
                .keyboardShortcut("p", modifiers: .command)
            }
        }
        .fileImporter(
            isPresented: $state.showFileImporter,
            allowedContentTypes: [.plainText, UTType(filenameExtension: "md")!],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    appState.loadFile(from: url)
                }
            case .failure:
                break
            }
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
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url = url {
                    DispatchQueue.main.async {
                        appState.loadFile(from: url)
                    }
                }
            }
            return true
        }
    }
}
