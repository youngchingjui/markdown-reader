import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState

        Group {
            if appState.markdownContent.isEmpty {
                WelcomeView()
            } else {
                MarkdownRenderView(
                    markdown: appState.markdownContent,
                    fontSize: appState.fontSize
                )
            }
        }
        .navigationTitle(appState.fileName)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { appState.showFileImporter = true }) {
                    Label("Open", systemImage: "doc.text")
                }
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
