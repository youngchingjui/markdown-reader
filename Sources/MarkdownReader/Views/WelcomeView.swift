import SwiftUI

struct WelcomeView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "doc.richtext")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("MarkdownReader")
                .font(.system(size: 28, weight: .light, design: .serif))
                .foregroundStyle(.primary)

            Text("Open a markdown file to start reading")
                .font(.body)
                .foregroundStyle(.secondary)

            Button("Open File...") {
                appState.showFileImporter = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)

            Text("or drag and drop a .md file here")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
