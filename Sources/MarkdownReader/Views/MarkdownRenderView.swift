import SwiftUI
import AppKit

struct MarkdownRenderView: NSViewRepresentable {
    let markdown: String
    let fontSize: CGFloat

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = true
        scrollView.backgroundColor = .textBackgroundColor
        scrollView.autoresizingMask = [.width, .height]
        scrollView.scrollerStyle = .overlay

        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.isRichText = true
        textView.textContainerInset = NSSize(width: 80, height: 48)
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.size = NSSize(width: 600, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

        scrollView.documentView = textView

        applyMarkdown(to: textView)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        applyMarkdown(to: textView)
    }

    private func applyMarkdown(to textView: NSTextView) {
        let attributed = renderMarkdown(markdown, fontSize: fontSize)
        textView.textStorage?.setAttributedString(attributed)
    }
}

// MARK: - Markdown → NSAttributedString renderer

private func renderMarkdown(_ markdown: String, fontSize: CGFloat) -> NSAttributedString {
    let result = NSMutableAttributedString()
    let lines = markdown.components(separatedBy: "\n")

    let bodyFont = NSFont.systemFont(ofSize: fontSize, weight: .regular)
    let bodyColor = NSColor.textColor

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = fontSize * 0.5
    paragraphStyle.paragraphSpacing = fontSize * 0.8

    var inCodeBlock = false
    var codeBlockLines: [String] = []
    var codeBlockLanguage = "" // reserved for future syntax highlighting
    var inBlockquote = false
    var blockquoteLines: [String] = []

    func flushBlockquote() {
        guard !blockquoteLines.isEmpty else { return }
        let text = blockquoteLines.joined(separator: "\n")
        let bqStyle = NSMutableParagraphStyle()
        bqStyle.lineSpacing = fontSize * 0.4
        bqStyle.paragraphSpacing = fontSize * 0.4
        bqStyle.headIndent = 24
        bqStyle.firstLineHeadIndent = 24

        let bqAttr = NSMutableAttributedString(string: text + "\n\n", attributes: [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .regular),
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: bqStyle,
        ])

        // Add a left border via an attachment isn't straightforward,
        // so we use italic to visually differentiate blockquotes
        bqAttr.addAttribute(.font, value: NSFont.systemFont(ofSize: fontSize).italic(), range: NSRange(location: 0, length: bqAttr.length))

        result.append(bqAttr)
        blockquoteLines.removeAll()
        inBlockquote = false
    }

    func flushCodeBlock() {
        guard !codeBlockLines.isEmpty else { return }
        let code = codeBlockLines.joined(separator: "\n")

        let codeStyle = NSMutableParagraphStyle()
        codeStyle.lineSpacing = fontSize * 0.2
        codeStyle.paragraphSpacingBefore = fontSize * 0.4
        codeStyle.paragraphSpacing = fontSize * 0.4

        let codeAttr = NSMutableAttributedString(string: code + "\n\n", attributes: [
            .font: NSFont.monospacedSystemFont(ofSize: fontSize * 0.88, weight: .regular),
            .foregroundColor: NSColor.textColor.withAlphaComponent(0.85),
            .backgroundColor: NSColor.quaternaryLabelColor.withAlphaComponent(0.15),
            .paragraphStyle: codeStyle,
        ])

        result.append(codeAttr)
        codeBlockLines.removeAll()
        codeBlockLanguage = ""
        inCodeBlock = false
    }

    for line in lines {
        // Code blocks
        if line.hasPrefix("```") {
            if inCodeBlock {
                flushCodeBlock()
            } else {
                flushBlockquote()
                inCodeBlock = true
                codeBlockLanguage = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
            }
            continue
        }

        if inCodeBlock {
            codeBlockLines.append(line)
            continue
        }

        // Blockquotes
        if line.hasPrefix("> ") || line == ">" {
            inBlockquote = true
            let content = line.hasPrefix("> ") ? String(line.dropFirst(2)) : ""
            blockquoteLines.append(content)
            continue
        } else if inBlockquote {
            flushBlockquote()
        }

        // Blank lines
        if line.trimmingCharacters(in: .whitespaces).isEmpty {
            result.append(NSAttributedString(string: "\n", attributes: [
                .font: bodyFont,
                .paragraphStyle: {
                    let s = NSMutableParagraphStyle()
                    s.paragraphSpacing = fontSize * 0.3
                    return s
                }(),
            ]))
            continue
        }

        // Headings
        if line.hasPrefix("# ") {
            flushBlockquote()
            let text = String(line.dropFirst(2))
            let headingStyle = NSMutableParagraphStyle()
            headingStyle.paragraphSpacingBefore = fontSize * 1.6
            headingStyle.paragraphSpacing = fontSize * 0.6
            headingStyle.lineSpacing = fontSize * 0.2

            result.append(NSAttributedString(string: text + "\n", attributes: [
                .font: NSFont.systemFont(ofSize: fontSize * 2.0, weight: .bold),
                .foregroundColor: bodyColor,
                .paragraphStyle: headingStyle,
            ]))
            continue
        }

        if line.hasPrefix("## ") {
            flushBlockquote()
            let text = String(line.dropFirst(3))
            let headingStyle = NSMutableParagraphStyle()
            headingStyle.paragraphSpacingBefore = fontSize * 1.4
            headingStyle.paragraphSpacing = fontSize * 0.4
            headingStyle.lineSpacing = fontSize * 0.2

            result.append(NSAttributedString(string: text + "\n", attributes: [
                .font: NSFont.systemFont(ofSize: fontSize * 1.6, weight: .semibold),
                .foregroundColor: bodyColor,
                .paragraphStyle: headingStyle,
            ]))
            continue
        }

        if line.hasPrefix("### ") {
            flushBlockquote()
            let text = String(line.dropFirst(4))
            let headingStyle = NSMutableParagraphStyle()
            headingStyle.paragraphSpacingBefore = fontSize * 1.2
            headingStyle.paragraphSpacing = fontSize * 0.3
            headingStyle.lineSpacing = fontSize * 0.2

            result.append(NSAttributedString(string: text + "\n", attributes: [
                .font: NSFont.systemFont(ofSize: fontSize * 1.3, weight: .semibold),
                .foregroundColor: bodyColor,
                .paragraphStyle: headingStyle,
            ]))
            continue
        }

        if line.hasPrefix("#### ") {
            flushBlockquote()
            let text = String(line.dropFirst(5))
            let headingStyle = NSMutableParagraphStyle()
            headingStyle.paragraphSpacingBefore = fontSize * 1.0
            headingStyle.paragraphSpacing = fontSize * 0.2

            result.append(NSAttributedString(string: text + "\n", attributes: [
                .font: NSFont.systemFont(ofSize: fontSize * 1.1, weight: .semibold),
                .foregroundColor: bodyColor,
                .paragraphStyle: headingStyle,
            ]))
            continue
        }

        // Horizontal rule
        if line.trimmingCharacters(in: .whitespaces).allSatisfy({ $0 == "-" || $0 == "*" || $0 == "_" })
            && line.trimmingCharacters(in: .whitespaces).count >= 3
        {
            let hrStyle = NSMutableParagraphStyle()
            hrStyle.paragraphSpacingBefore = fontSize
            hrStyle.paragraphSpacing = fontSize

            result.append(NSAttributedString(string: "⸻\n", attributes: [
                .font: bodyFont,
                .foregroundColor: NSColor.separatorColor,
                .paragraphStyle: hrStyle,
            ]))
            continue
        }

        // Unordered list items
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ") {
            let indent = line.prefix(while: { $0 == " " || $0 == "\t" }).count
            let text = String(trimmed.dropFirst(2))

            let listStyle = NSMutableParagraphStyle()
            listStyle.lineSpacing = fontSize * 0.35
            listStyle.paragraphSpacing = fontSize * 0.2
            let baseIndent: CGFloat = CGFloat(indent / 2) * 20 + 24
            listStyle.headIndent = baseIndent
            listStyle.firstLineHeadIndent = baseIndent - 16

            let bullet = "•  "
            let styledText = applyInlineStyles(to: bullet + text + "\n", fontSize: fontSize, bodyFont: bodyFont, bodyColor: bodyColor)
            styledText.addAttribute(.paragraphStyle, value: listStyle, range: NSRange(location: 0, length: styledText.length))
            result.append(styledText)
            continue
        }

        // Ordered list items
        if let match = trimmed.range(of: #"^\d+\.\s"#, options: .regularExpression) {
            let number = trimmed[match].trimmingCharacters(in: .whitespaces)
            let text = String(trimmed[match.upperBound...])

            let listStyle = NSMutableParagraphStyle()
            listStyle.lineSpacing = fontSize * 0.35
            listStyle.paragraphSpacing = fontSize * 0.2
            listStyle.headIndent = 28
            listStyle.firstLineHeadIndent = 4

            let styledText = applyInlineStyles(to: number + " " + text + "\n", fontSize: fontSize, bodyFont: bodyFont, bodyColor: bodyColor)
            styledText.addAttribute(.paragraphStyle, value: listStyle, range: NSRange(location: 0, length: styledText.length))
            result.append(styledText)
            continue
        }

        // Regular paragraph
        let styledText = applyInlineStyles(to: line + "\n", fontSize: fontSize, bodyFont: bodyFont, bodyColor: bodyColor)
        styledText.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: styledText.length))
        result.append(styledText)
    }

    // Flush any remaining blocks
    flushBlockquote()
    flushCodeBlock()

    return result
}

// MARK: - Inline style rendering (bold, italic, code, links)

private func applyInlineStyles(
    to text: String,
    fontSize: CGFloat,
    bodyFont: NSFont,
    bodyColor: NSColor
) -> NSMutableAttributedString {
    let result = NSMutableAttributedString(string: text, attributes: [
        .font: bodyFont,
        .foregroundColor: bodyColor,
    ])

    // Inline code: `code`
    applyPattern(#"`([^`]+)`"#, to: result, fontSize: fontSize) { range, match in
        let codeFont = NSFont.monospacedSystemFont(ofSize: fontSize * 0.88, weight: .regular)
        result.addAttributes([
            .font: codeFont,
            .foregroundColor: NSColor.systemOrange.blended(withFraction: 0.3, of: bodyColor) ?? bodyColor,
            .backgroundColor: NSColor.quaternaryLabelColor.withAlphaComponent(0.2),
        ], range: range)
    }

    // Bold+Italic: ***text*** or ___text___
    applyPattern(#"(\*\*\*|___)(.+?)\1"#, to: result, fontSize: fontSize) { range, match in
        let boldItalicFont = NSFont.systemFont(ofSize: fontSize, weight: .bold).italic()
        result.addAttribute(.font, value: boldItalicFont, range: range)
    }

    // Bold: **text** or __text__
    applyPattern(#"(\*\*|__)(.+?)\1"#, to: result, fontSize: fontSize) { range, match in
        let boldFont = NSFont.systemFont(ofSize: fontSize, weight: .semibold)
        result.addAttribute(.font, value: boldFont, range: range)
    }

    // Italic: *text* or _text_
    applyPattern(#"(?<!\*)(\*|_)(?!\*)(.+?)(?<!\*)\1(?!\*)"#, to: result, fontSize: fontSize) { range, match in
        let italicFont = NSFont.systemFont(ofSize: fontSize, weight: .regular).italic()
        result.addAttribute(.font, value: italicFont, range: range)
    }

    // Links: [text](url)
    let linkPattern = #"\[([^\]]+)\]\(([^)]+)\)"#
    if let regex = try? NSRegularExpression(pattern: linkPattern) {
        let nsString = result.string as NSString
        let matches = regex.matches(in: result.string, range: NSRange(location: 0, length: nsString.length))

        for match in matches.reversed() {
            let fullRange = match.range
            let textRange = match.range(at: 1)
            let urlRange = match.range(at: 2)

            let linkText = nsString.substring(with: textRange)
            let urlString = nsString.substring(with: urlRange)

            let replacement = NSMutableAttributedString(string: linkText, attributes: [
                .font: bodyFont,
                .foregroundColor: NSColor.linkColor,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
            ])

            if let url = URL(string: urlString) {
                replacement.addAttribute(.link, value: url, range: NSRange(location: 0, length: linkText.count))
            }

            result.replaceCharacters(in: fullRange, with: replacement)
        }
    }

    // Strikethrough: ~~text~~
    applyPattern(#"~~(.+?)~~"#, to: result, fontSize: fontSize) { range, _ in
        result.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        result.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: range)
    }

    return result
}

private func applyPattern(
    _ pattern: String,
    to attributedString: NSMutableAttributedString,
    fontSize: CGFloat,
    handler: (NSRange, NSTextCheckingResult) -> Void
) {
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
    let nsString = attributedString.string as NSString
    let matches = regex.matches(in: attributedString.string, range: NSRange(location: 0, length: nsString.length))

    for match in matches.reversed() {
        handler(match.range, match)
    }
}

// MARK: - NSFont italic helper

extension NSFont {
    func italic() -> NSFont {
        let descriptor = fontDescriptor.withSymbolicTraits(.italic)
        return NSFont(descriptor: descriptor, size: pointSize) ?? self
    }
}
