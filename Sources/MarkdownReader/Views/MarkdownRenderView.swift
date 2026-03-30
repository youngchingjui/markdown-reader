import SwiftUI
import AppKit
import Highlighter

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

private func serifFont(ofSize size: CGFloat, weight: NSFont.Weight) -> NSFont {
    let systemFont = NSFont.systemFont(ofSize: size, weight: weight)
    if let serifDescriptor = systemFont.fontDescriptor.withDesign(.serif) {
        return NSFont(descriptor: serifDescriptor, size: size) ?? systemFont
    }
    return systemFont
}

private func renderMarkdown(_ markdown: String, fontSize: CGFloat) -> NSAttributedString {
    let result = NSMutableAttributedString()
    let lines = markdown.components(separatedBy: "\n")

    let bodyFont = serifFont(ofSize: fontSize, weight: .regular)
    let bodyColor = NSColor.textColor

    let bodyLineHeight = fontSize * 1.6
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.minimumLineHeight = bodyLineHeight
    paragraphStyle.maximumLineHeight = bodyLineHeight
    paragraphStyle.lineSpacing = 0
    paragraphStyle.paragraphSpacing = fontSize * 0.5

    var inCodeBlock = false
    var codeBlockLines: [String] = []
    var codeBlockLanguage = ""
    var inBlockquote = false
    var blockquoteLines: [String] = []
    var tableLines: [String] = []

    func flushBlockquote() {
        guard !blockquoteLines.isEmpty else { return }
        let text = blockquoteLines.joined(separator: "\n")
        let bqStyle = NSMutableParagraphStyle()
        bqStyle.lineSpacing = fontSize * 0.45
        bqStyle.paragraphSpacing = fontSize * 0.5
        bqStyle.headIndent = 28
        bqStyle.firstLineHeadIndent = 28

        let bqFont = serifFont(ofSize: fontSize, weight: .regular).italic()
        let bqAttr = NSMutableAttributedString(string: text + "\n\n", attributes: [
            .font: bqFont,
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: bqStyle,
        ])
        result.append(bqAttr)
        blockquoteLines.removeAll()
        inBlockquote = false
    }

    func flushCodeBlock() {
        guard !codeBlockLines.isEmpty else { return }
        let code = codeBlockLines.joined(separator: "\n")
        let codeFontSize = fontSize * 0.82
        let codeLineHeight = codeFontSize * 1.45
        let codeFont = NSFont.monospacedSystemFont(ofSize: codeFontSize, weight: .regular)

        let codeStyle = NSMutableParagraphStyle()
        codeStyle.minimumLineHeight = codeLineHeight
        codeStyle.maximumLineHeight = codeLineHeight
        codeStyle.lineSpacing = 0
        codeStyle.paragraphSpacing = 0

        let textBlock = NSTextBlock()
        textBlock.backgroundColor = NSColor.quaternaryLabelColor.withAlphaComponent(0.08)
        textBlock.setContentWidth(100, type: .percentageValueType)
        textBlock.setWidth(12, type: .absoluteValueType, for: .padding)
        textBlock.setWidth(6, type: .absoluteValueType, for: .padding, edge: .minY)
        textBlock.setWidth(6, type: .absoluteValueType, for: .padding, edge: .maxY)
        textBlock.setWidth(8, type: .absoluteValueType, for: .margin, edge: .minY)
        textBlock.setWidth(8, type: .absoluteValueType, for: .margin, edge: .maxY)
        codeStyle.textBlocks = [textBlock]

        // Try syntax highlighting
        var codeAttr: NSMutableAttributedString
        let lang = codeBlockLanguage.isEmpty ? nil : codeBlockLanguage
        if let highlighter = Highlighter() {
            highlighter.setTheme("atom-one-light")
            highlighter.theme.setCodeFont(codeFont)
            if let highlighted = highlighter.highlight(code, as: lang) {
                codeAttr = NSMutableAttributedString(attributedString: highlighted)
                codeAttr.append(NSAttributedString(string: "\n"))
            } else {
                codeAttr = NSMutableAttributedString(string: code + "\n", attributes: [
                    .font: codeFont,
                    .foregroundColor: NSColor.textColor.withAlphaComponent(0.75),
                ])
            }
        } else {
            codeAttr = NSMutableAttributedString(string: code + "\n", attributes: [
                .font: codeFont,
                .foregroundColor: NSColor.textColor.withAlphaComponent(0.75),
            ])
        }

        // Apply paragraph style and font across entire range
        let fullRange = NSRange(location: 0, length: codeAttr.length)
        codeAttr.addAttribute(.paragraphStyle, value: codeStyle, range: fullRange)
        codeAttr.addAttribute(.font, value: codeFont, range: fullRange)

        result.append(codeAttr)
        let spacer = NSMutableParagraphStyle()
        spacer.paragraphSpacing = fontSize * 0.3
        result.append(NSAttributedString(string: "\n", attributes: [.font: bodyFont, .paragraphStyle: spacer]))

        codeBlockLines.removeAll()
        codeBlockLanguage = ""
        inCodeBlock = false
    }

    func flushTable() {
        guard !tableLines.isEmpty else { return }

        // Parse table rows into cells
        var rows: [[String]] = []
        var hasSeparator = false

        for (i, line) in tableLines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let stripped = trimmed.hasPrefix("|") ? String(trimmed.dropFirst()) : trimmed
            let endStripped = stripped.hasSuffix("|") ? String(stripped.dropLast()) : stripped

            // Check if separator row (e.g. |---|---|)
            let isSeparator = endStripped.split(separator: "|").allSatisfy { cell in
                let c = cell.trimmingCharacters(in: .whitespaces)
                return c.allSatisfy({ $0 == "-" || $0 == ":" }) && c.count >= 1
            }

            if isSeparator && i > 0 {
                hasSeparator = true
                continue
            }

            let cells = endStripped.split(separator: "|", omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespaces) }
            rows.append(cells)
        }

        guard !rows.isEmpty else { tableLines.removeAll(); return }

        let colCount = rows.map(\.count).max() ?? 0
        var colWidths = [Int](repeating: 0, count: colCount)
        for row in rows {
            for (j, cell) in row.enumerated() where j < colCount {
                colWidths[j] = max(colWidths[j], cell.count)
            }
        }

        let tableFont = NSFont.monospacedSystemFont(ofSize: fontSize * 0.88, weight: .regular)
        let tableBoldFont = NSFont.monospacedSystemFont(ofSize: fontSize * 0.88, weight: .semibold)

        let tableStyle = NSMutableParagraphStyle()
        tableStyle.lineSpacing = fontSize * 0.15
        tableStyle.paragraphSpacing = 0

        let tableBlock = NSTextBlock()
        tableBlock.backgroundColor = NSColor.quaternaryLabelColor.withAlphaComponent(0.08)
        tableBlock.setContentWidth(100, type: .percentageValueType)
        tableBlock.setWidth(12, type: .absoluteValueType, for: .padding)
        tableBlock.setWidth(8, type: .absoluteValueType, for: .margin, edge: .minY)
        tableBlock.setWidth(8, type: .absoluteValueType, for: .margin, edge: .maxY)
        tableStyle.textBlocks = [tableBlock]

        var tableText = ""
        for (i, row) in rows.enumerated() {
            var line = ""
            for j in 0..<colCount {
                let cell = j < row.count ? row[j] : ""
                let padded = cell.padding(toLength: colWidths[j], withPad: " ", startingAt: 0)
                if j > 0 { line += "  │  " }
                line += padded
            }
            tableText += line + "\n"

            // Add separator after header row
            if i == 0 && hasSeparator {
                var sep = ""
                for j in 0..<colCount {
                    if j > 0 { sep += "──┼──" }
                    sep += String(repeating: "─", count: colWidths[j])
                }
                tableText += sep + "\n"
            }
        }

        let tableAttr = NSMutableAttributedString(string: tableText, attributes: [
            .font: tableFont,
            .foregroundColor: bodyColor,
            .paragraphStyle: tableStyle,
        ])

        // Bold the header row
        if hasSeparator, let firstNewline = tableText.firstIndex(of: "\n") {
            let headerLength = tableText.distance(from: tableText.startIndex, to: firstNewline)
            tableAttr.addAttribute(.font, value: tableBoldFont, range: NSRange(location: 0, length: headerLength))
        }

        result.append(tableAttr)
        let spacer = NSMutableParagraphStyle()
        spacer.paragraphSpacing = fontSize * 0.4
        result.append(NSAttributedString(string: "\n", attributes: [.font: bodyFont, .paragraphStyle: spacer]))

        tableLines.removeAll()
    }

    for line in lines {
        // Code blocks
        if line.hasPrefix("```") {
            if inCodeBlock {
                flushCodeBlock()
            } else {
                flushBlockquote()
                flushTable()
                inCodeBlock = true
                codeBlockLanguage = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
            }
            continue
        }

        if inCodeBlock {
            codeBlockLines.append(line)
            continue
        }

        // Table detection: lines that contain | and look like table rows
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
        if trimmedLine.hasPrefix("|") && trimmedLine.hasSuffix("|") {
            flushBlockquote()
            tableLines.append(line)
            continue
        } else if !tableLines.isEmpty {
            flushTable()
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
        if line.hasPrefix("#### ") {
            flushBlockquote()
            let text = String(line.dropFirst(5))
            let headingStyle = NSMutableParagraphStyle()
            headingStyle.paragraphSpacingBefore = fontSize * 1.2
            headingStyle.paragraphSpacing = fontSize * 0.3

            let styledText = applyInlineStyles(to: text, fontSize: fontSize * 1.05,
                bodyFont: serifFont(ofSize: fontSize * 1.05, weight: .semibold),
                bodyColor: bodyColor)
            styledText.append(NSAttributedString(string: "\n"))
            styledText.addAttribute(.paragraphStyle, value: headingStyle, range: NSRange(location: 0, length: styledText.length))
            result.append(styledText)
            continue
        }

        if line.hasPrefix("### ") {
            flushBlockquote()
            let text = String(line.dropFirst(4))
            let headingStyle = NSMutableParagraphStyle()
            headingStyle.paragraphSpacingBefore = fontSize * 1.4
            headingStyle.paragraphSpacing = fontSize * 0.35
            headingStyle.lineSpacing = fontSize * 0.2

            let styledText = applyInlineStyles(to: text, fontSize: fontSize * 1.2,
                bodyFont: serifFont(ofSize: fontSize * 1.2, weight: .semibold),
                bodyColor: bodyColor)
            styledText.append(NSAttributedString(string: "\n"))
            styledText.addAttribute(.paragraphStyle, value: headingStyle, range: NSRange(location: 0, length: styledText.length))
            result.append(styledText)
            continue
        }

        if line.hasPrefix("## ") {
            flushBlockquote()
            let text = String(line.dropFirst(3))
            let headingStyle = NSMutableParagraphStyle()
            headingStyle.paragraphSpacingBefore = fontSize * 1.8
            headingStyle.paragraphSpacing = fontSize * 0.5
            headingStyle.lineSpacing = fontSize * 0.2

            let styledText = applyInlineStyles(to: text, fontSize: fontSize * 1.5,
                bodyFont: serifFont(ofSize: fontSize * 1.5, weight: .semibold),
                bodyColor: bodyColor)
            styledText.append(NSAttributedString(string: "\n"))
            styledText.addAttribute(.paragraphStyle, value: headingStyle, range: NSRange(location: 0, length: styledText.length))
            result.append(styledText)
            continue
        }

        if line.hasPrefix("# ") {
            flushBlockquote()
            let text = String(line.dropFirst(2))
            let headingStyle = NSMutableParagraphStyle()
            headingStyle.paragraphSpacingBefore = fontSize * 2.0
            headingStyle.paragraphSpacing = fontSize * 0.8
            headingStyle.lineSpacing = fontSize * 0.2

            let styledText = applyInlineStyles(to: text, fontSize: fontSize * 2.2,
                bodyFont: serifFont(ofSize: fontSize * 2.2, weight: .bold),
                bodyColor: bodyColor)
            styledText.append(NSAttributedString(string: "\n"))
            styledText.addAttribute(.paragraphStyle, value: headingStyle, range: NSRange(location: 0, length: styledText.length))
            result.append(styledText)
            continue
        }

        // Horizontal rule
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.allSatisfy({ $0 == "-" || $0 == "*" || $0 == "_" })
            && trimmed.count >= 3
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
        if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ") {
            let indent = line.prefix(while: { $0 == " " || $0 == "\t" }).count
            let text = String(trimmed.dropFirst(2))

            let listStyle = NSMutableParagraphStyle()
            listStyle.minimumLineHeight = bodyLineHeight
            listStyle.maximumLineHeight = bodyLineHeight
            listStyle.lineSpacing = 0
            listStyle.paragraphSpacing = fontSize * 0.15
            let baseIndent: CGFloat = CGFloat(indent / 2) * 20 + 24
            listStyle.headIndent = baseIndent
            listStyle.firstLineHeadIndent = baseIndent - 16

            let bullet = "•  "
            let styledText = applyInlineStyles(to: bullet + text, fontSize: fontSize, bodyFont: bodyFont, bodyColor: bodyColor)
            styledText.append(NSAttributedString(string: "\n"))
            styledText.addAttribute(.paragraphStyle, value: listStyle, range: NSRange(location: 0, length: styledText.length))
            result.append(styledText)
            continue
        }

        // Ordered list items
        if let match = trimmed.range(of: #"^\d+\.\s"#, options: .regularExpression) {
            let number = trimmed[match].trimmingCharacters(in: .whitespaces)
            let text = String(trimmed[match.upperBound...])

            let listStyle = NSMutableParagraphStyle()
            listStyle.minimumLineHeight = bodyLineHeight
            listStyle.maximumLineHeight = bodyLineHeight
            listStyle.lineSpacing = 0
            listStyle.paragraphSpacing = fontSize * 0.15
            listStyle.headIndent = 28
            listStyle.firstLineHeadIndent = 4

            let styledText = applyInlineStyles(to: number + " " + text, fontSize: fontSize, bodyFont: bodyFont, bodyColor: bodyColor)
            styledText.append(NSAttributedString(string: "\n"))
            styledText.addAttribute(.paragraphStyle, value: listStyle, range: NSRange(location: 0, length: styledText.length))
            result.append(styledText)
            continue
        }

        // Regular paragraph
        let styledText = applyInlineStyles(to: line, fontSize: fontSize, bodyFont: bodyFont, bodyColor: bodyColor)
        styledText.append(NSAttributedString(string: "\n"))
        styledText.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: styledText.length))
        result.append(styledText)
    }

    // Flush any remaining blocks
    flushBlockquote()
    flushCodeBlock()
    flushTable()

    return result
}

// MARK: - Inline style rendering (bold, italic, code, links) with delimiter stripping

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

    // Links: [text](url)
    stripAndReplace(pattern: #"\[([^\]]+)\]\(([^)]+)\)"#, in: result) { match, nsString in
        let linkText = nsString.substring(with: match.range(at: 1))
        let urlString = nsString.substring(with: match.range(at: 2))
        let replacement = NSMutableAttributedString(string: linkText, attributes: [
            .font: bodyFont,
            .foregroundColor: NSColor.controlAccentColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
        ])
        if let url = URL(string: urlString) {
            replacement.addAttribute(.link, value: url, range: NSRange(location: 0, length: linkText.count))
        }
        return replacement
    }

    // Inline code: `code` — process before bold/italic to avoid conflicts
    stripAndReplace(pattern: #"`([^`]+)`"#, in: result) { match, nsString in
        let code = nsString.substring(with: match.range(at: 1))
        let inlineCodeFont = NSFont.monospacedSystemFont(ofSize: fontSize * 0.84, weight: .regular)
        return NSMutableAttributedString(string: "\u{2006}" + code + "\u{2006}", attributes: [
            .font: inlineCodeFont,
            .foregroundColor: NSColor.textColor.withAlphaComponent(0.8),
            .backgroundColor: NSColor.quaternaryLabelColor.withAlphaComponent(0.12),
        ])
    }

    // Bold+Italic: ***text*** or ___text___
    stripAndReplace(pattern: #"(\*\*\*|___)(.+?)\1"#, in: result) { match, nsString in
        let content = nsString.substring(with: match.range(at: 2))
        return NSMutableAttributedString(string: content, attributes: [
            .font: serifFont(ofSize: fontSize, weight: .bold).italic(),
            .foregroundColor: bodyColor,
        ])
    }

    // Bold: **text** or __text__
    stripAndReplace(pattern: #"(\*\*|__)(.+?)\1"#, in: result) { match, nsString in
        let content = nsString.substring(with: match.range(at: 2))
        return NSMutableAttributedString(string: content, attributes: [
            .font: serifFont(ofSize: fontSize, weight: .semibold),
            .foregroundColor: bodyColor,
        ])
    }

    // Italic: *text* or _text_ (avoid matching mid-word underscores)
    stripAndReplace(pattern: #"\*([^*\n]+?)\*"#, in: result) { match, nsString in
        let content = nsString.substring(with: match.range(at: 1))
        return NSMutableAttributedString(string: content, attributes: [
            .font: serifFont(ofSize: fontSize, weight: .regular).italic(),
            .foregroundColor: bodyColor,
        ])
    }
    stripAndReplace(pattern: #"(?<!\w)_([^_\n]+?)_(?!\w)"#, in: result) { match, nsString in
        let content = nsString.substring(with: match.range(at: 1))
        return NSMutableAttributedString(string: content, attributes: [
            .font: serifFont(ofSize: fontSize, weight: .regular).italic(),
            .foregroundColor: bodyColor,
        ])
    }

    // Strikethrough: ~~text~~
    stripAndReplace(pattern: #"~~(.+?)~~"#, in: result) { match, nsString in
        let content = nsString.substring(with: match.range(at: 1))
        return NSMutableAttributedString(string: content, attributes: [
            .font: bodyFont,
            .foregroundColor: NSColor.secondaryLabelColor,
            .strikethroughStyle: NSUnderlineStyle.single.rawValue,
        ])
    }

    return result
}

/// Find regex matches and replace each with a styled attributed string (processes in reverse to preserve indices)
private func stripAndReplace(
    pattern: String,
    in attributedString: NSMutableAttributedString,
    replacement: (NSTextCheckingResult, NSString) -> NSMutableAttributedString
) {
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
    let nsString = attributedString.string as NSString
    let matches = regex.matches(in: attributedString.string, range: NSRange(location: 0, length: nsString.length))

    for match in matches.reversed() {
        let rep = replacement(match, nsString)
        attributedString.replaceCharacters(in: match.range, with: rep)
    }
}

// MARK: - NSFont italic helper

extension NSFont {
    func italic() -> NSFont {
        let descriptor = fontDescriptor.withSymbolicTraits(.italic)
        return NSFont(descriptor: descriptor, size: pointSize) ?? self
    }
}
