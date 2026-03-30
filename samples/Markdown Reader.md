# Markdown Reader

A beautiful, native macOS app for reading markdown files — distraction-free, with clean typography and syntax highlighting.

## Why Markdown Reader?

Open any `.md` file and get a beautifully typeset document — no distractions. Just your words, set in clean serif type.

### Features

- **Workspace folders** — add entire project directories and browse all your markdown files from the sidebar
- **Quick Open** — press `Cmd+P` to fuzzy-search across every file in your workspaces
- **Syntax highlighting** — code blocks are highlighted with language-aware coloring
- **Adjustable font size** — scale text up or down with `Cmd+` and `Cmd-`
- **Native macOS** — built with SwiftUI, supports dark mode, respects your system preferences

## Rendering Showcase

The renderer handles all standard markdown formatting. **Bold**, *italic*, ***bold italic***, ~~strikethrough~~, `inline code`, and [links](https://example.com) all render inline.

> "The best tools are the ones you forget you're using."

### Code Blocks

Fenced code blocks get full syntax highlighting:

```swift
struct Document {
    let title: String
    let wordCount: Int

    var readingTime: String {
        let minutes = max(1, wordCount / 200)
        return "\(minutes) min read"
    }
}
```

```python
def word_frequency(text: str) -> dict[str, int]:
    words = text.lower().split()
    freq = {}
    for word in words:
        clean = word.strip(".,!?;:")
        freq[clean] = freq.get(clean, 0) + 1
    return dict(sorted(freq.items(), key=lambda x: -x[1]))
```

### Tables

| Feature | Status |
|---------|--------|
| Headings (H1–H4) | Supported |
| Ordered & unordered lists | Supported |
| Code blocks with highlighting | Supported |
| Block quotes | Supported |
| Tables | Supported |
| Inline formatting | Supported |

### Lists

1. Open a file or add a workspace folder
2. Browse your files in the sidebar
3. Use Quick Open to jump to any file instantly

---

Built for macOS 14+. Native. Fast. Beautiful.
