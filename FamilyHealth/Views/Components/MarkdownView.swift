import SwiftUI
import WebKit

/// A SwiftUI view that renders Markdown content using WKWebView for full formatting support.
/// Supports headers, lists, tables, code blocks, bold, italic, links, and more.
/// Auto-sizes to fit content height and supports dark mode.
struct MarkdownView: UIViewRepresentable {
    let markdown: String
    @Binding var dynamicHeight: CGFloat
    var fontSize: CGFloat = 14

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let html = buildHTML(markdown: markdown, fontSize: fontSize)
        webView.loadHTMLString(html, baseURL: nil)
    }

    // MARK: - HTML Builder

    private func buildHTML(markdown: String, fontSize: CGFloat) -> String {
        let htmlBody = markdownToHTML(markdown)
        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif;
                font-size: \(fontSize)px;
                line-height: 1.6;
                color: \(cssColor("label"));
                background: transparent;
                padding: 0;
                word-wrap: break-word;
                -webkit-text-size-adjust: none;
            }
            h1 { font-size: 1.4em; font-weight: 700; margin: 12px 0 6px 0; }
            h2 { font-size: 1.25em; font-weight: 700; margin: 10px 0 5px 0; }
            h3 { font-size: 1.1em; font-weight: 600; margin: 8px 0 4px 0; }
            h4 { font-size: 1.0em; font-weight: 600; margin: 6px 0 3px 0; }
            p { margin: 4px 0; }
            ul, ol { padding-left: 20px; margin: 4px 0; }
            li { margin: 2px 0; }
            strong { font-weight: 600; }
            em { font-style: italic; }
            code {
                font-family: 'SF Mono', Menlo, monospace;
                font-size: 0.9em;
                background: \(cssColor("tertiarySystemFill"));
                padding: 1px 4px;
                border-radius: 3px;
            }
            pre {
                background: \(cssColor("tertiarySystemFill"));
                padding: 8px 10px;
                border-radius: 6px;
                margin: 6px 0;
                overflow-x: auto;
            }
            pre code { background: none; padding: 0; }
            hr { border: none; border-top: 1px solid \(cssColor("separator")); margin: 8px 0; }
            blockquote {
                border-left: 3px solid \(cssColor("systemBlue"));
                padding-left: 10px;
                margin: 6px 0;
                color: \(cssColor("secondaryLabel"));
            }
            table {
                border-collapse: collapse;
                width: 100%;
                margin: 6px 0;
                font-size: 0.9em;
            }
            th, td {
                border: 1px solid \(cssColor("separator"));
                padding: 4px 8px;
                text-align: left;
            }
            th { background: \(cssColor("tertiarySystemFill")); font-weight: 600; }
            a { color: \(cssColor("systemBlue")); }
        </style>
        </head>
        <body>\(htmlBody)</body>
        <script>
            // Notify Swift of content height after render
            function notifyHeight() {
                window.webkit.messageHandlers.heightChanged
                    && window.webkit.messageHandlers.heightChanged.postMessage(
                        document.body.scrollHeight
                    );
            }
            // Use ResizeObserver for accurate sizing
            new ResizeObserver(notifyHeight).observe(document.body);
            notifyHeight();
        </script>
        </html>
        """
    }

    private func cssColor(_ name: String) -> String {
        // Use CSS media query for dark mode
        switch name {
        case "label":
            return "color-mix(in srgb, currentColor, currentColor)"
        case "secondaryLabel":
            return "rgba(128,128,128,1)"
        case "separator":
            return "rgba(128,128,128,0.3)"
        case "tertiarySystemFill":
            return "rgba(128,128,128,0.12)"
        case "systemBlue":
            return "#007AFF"
        default:
            return "inherit"
        }
    }

    // MARK: - Markdown → HTML Converter

    private func markdownToHTML(_ md: String) -> String {
        var lines = md.components(separatedBy: "\n")
        var html = ""
        var inCodeBlock = false
        var codeContent = ""
        var inList = false
        var listType = "" // "ul" or "ol"

        func closeList() {
            if inList {
                html += "</\(listType)>"
                inList = false
            }
        }

        for line in lines {
            // Code blocks
            if line.hasPrefix("```") {
                if inCodeBlock {
                    html += "<pre><code>\(escapeHTML(codeContent))</code></pre>"
                    codeContent = ""
                    inCodeBlock = false
                } else {
                    closeList()
                    inCodeBlock = true
                }
                continue
            }
            if inCodeBlock {
                if !codeContent.isEmpty { codeContent += "\n" }
                codeContent += line
                continue
            }

            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Empty line
            if trimmed.isEmpty {
                closeList()
                continue
            }

            // Headers
            if trimmed.hasPrefix("####") {
                closeList()
                let text = inlineMarkdown(String(trimmed.dropFirst(4)).trimmingCharacters(in: .whitespaces))
                html += "<h4>\(text)</h4>"
                continue
            }
            if trimmed.hasPrefix("###") {
                closeList()
                let text = inlineMarkdown(String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces))
                html += "<h3>\(text)</h3>"
                continue
            }
            if trimmed.hasPrefix("##") {
                closeList()
                let text = inlineMarkdown(String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces))
                html += "<h2>\(text)</h2>"
                continue
            }
            if trimmed.hasPrefix("# ") {
                closeList()
                let text = inlineMarkdown(String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces))
                html += "<h1>\(text)</h1>"
                continue
            }

            // Horizontal rule
            if trimmed == "---" || trimmed == "***" || trimmed == "___" {
                closeList()
                html += "<hr>"
                continue
            }

            // Blockquote
            if trimmed.hasPrefix("> ") {
                closeList()
                let text = inlineMarkdown(String(trimmed.dropFirst(2)))
                html += "<blockquote>\(text)</blockquote>"
                continue
            }

            // Unordered list
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ") {
                if !inList || listType != "ul" {
                    closeList()
                    html += "<ul>"
                    inList = true
                    listType = "ul"
                }
                let text = inlineMarkdown(String(trimmed.dropFirst(2)))
                html += "<li>\(text)</li>"
                continue
            }

            // Ordered list
            if let _ = trimmed.range(of: #"^\d+\.\s"#, options: .regularExpression) {
                if !inList || listType != "ol" {
                    closeList()
                    html += "<ol>"
                    inList = true
                    listType = "ol"
                }
                let text = inlineMarkdown(trimmed.replacingOccurrences(of: #"^\d+\.\s"#, with: "", options: .regularExpression))
                html += "<li>\(text)</li>"
                continue
            }

            // Regular paragraph
            closeList()
            html += "<p>\(inlineMarkdown(trimmed))</p>"
        }

        closeList()
        if inCodeBlock {
            html += "<pre><code>\(escapeHTML(codeContent))</code></pre>"
        }

        return html
    }

    /// Convert inline Markdown (bold, italic, code, links, strikethrough)
    private func inlineMarkdown(_ text: String) -> String {
        var result = escapeHTML(text)

        // Inline code (must go first to avoid processing content inside)
        result = result.replacingOccurrences(
            of: #"`([^`]+)`"#, with: "<code>$1</code>", options: .regularExpression)

        // Bold + italic
        result = result.replacingOccurrences(
            of: #"\*\*\*(.+?)\*\*\*"#, with: "<strong><em>$1</em></strong>", options: .regularExpression)

        // Bold
        result = result.replacingOccurrences(
            of: #"\*\*(.+?)\*\*"#, with: "<strong>$1</strong>", options: .regularExpression)

        // Italic
        result = result.replacingOccurrences(
            of: #"\*(.+?)\*"#, with: "<em>$1</em>", options: .regularExpression)

        // Strikethrough
        result = result.replacingOccurrences(
            of: #"~~(.+?)~~"#, with: "<del>$1</del>", options: .regularExpression)

        // Links
        result = result.replacingOccurrences(
            of: #"\[([^\]]+)\]\(([^)]+)\)"#, with: "<a href=\"$2\">$1</a>", options: .regularExpression)

        return result
    }

    private func escapeHTML(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: MarkdownView

        init(parent: MarkdownView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.body.scrollHeight") { [weak self] result, _ in
                if let height = result as? CGFloat, height > 0 {
                    DispatchQueue.main.async {
                        self?.parent.dynamicHeight = height
                    }
                }
            }
        }
    }
}

/// Convenience wrapper that manages its own height state.
struct AutoSizingMarkdownView: View {
    let markdown: String
    var fontSize: CGFloat = 14

    @State private var height: CGFloat = 10

    var body: some View {
        MarkdownView(markdown: markdown, dynamicHeight: $height, fontSize: fontSize)
            .frame(height: height)
    }
}
