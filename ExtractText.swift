import AppKit
import Vision
import PDFKit

// MARK: - File Type Detection

enum FileCategory {
    case pdf
    case image
    case richDocument
    case plainText
}

func fileCategory(for path: String) -> FileCategory {
    let ext = (path as NSString).pathExtension.lowercased()
    switch ext {
    case "pdf":
        return .pdf
    case "png", "jpg", "jpeg", "tiff", "tif", "heic", "heics", "webp",
         "gif", "bmp", "jp2", "jxl":
        return .image
    case "docx", "doc", "odt", "rtf", "rtfd":
        return .richDocument
    default:
        return .plainText
    }
}

// MARK: - Text Sanitization

/// Removes non-displayable Unicode characters while preserving legitimate Unicode
/// (CJK, emoji, accented Latin, Arabic, Cyrillic, etc.)
func sanitizeText(_ text: String) -> String {
    return String(text.unicodeScalars.filter { scalar in
        let cat = scalar.properties.generalCategory

        // Remove control characters, except tab/newline/CR
        if cat == .control {
            return scalar.value == 0x09 || scalar.value == 0x0A || scalar.value == 0x0D
        }

        // Remove Private Use Area (custom PDF glyphs with no standard rendering)
        if cat == .privateUse { return false }

        // Remove format/invisible characters (zero-width spaces, soft hyphens, bidi marks, BOM)
        if cat == .format { return false }

        // Remove replacement characters (U+FFFD box-with-question-mark, U+FFFC object replacement)
        if scalar.value == 0xFFFD || scalar.value == 0xFFFC { return false }

        return true
    })
}

// MARK: - Text Extraction

func extractPDF(from url: URL) -> String {
    guard let doc = PDFDocument(url: url) else {
        return "[Could not open PDF]"
    }
    return doc.string ?? "[No text found in PDF]"
}

func extractImageOCR(from url: URL) -> String {
    guard let image = NSImage(contentsOf: url),
          let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
    else {
        return "[Could not load image]"
    }

    let semaphore = DispatchSemaphore(value: 0)
    var recognizedText = ""

    let request = VNRecognizeTextRequest { request, error in
        defer { semaphore.signal() }
        guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
        recognizedText = observations
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
    }
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true

    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    try? handler.perform([request])
    semaphore.wait()

    return recognizedText.isEmpty ? "[No text recognized in image]" : recognizedText
}

func extractRichDocument(from url: URL) -> String {
    do {
        let attrString = try NSAttributedString(url: url, options: [:], documentAttributes: nil)
        return attrString.string
    } catch {
        return "[Could not read document: \(error.localizedDescription)]"
    }
}

func extractPlainText(from url: URL) -> String {
    if let text = try? String(contentsOf: url, encoding: .utf8) { return text }
    if let text = try? String(contentsOf: url, encoding: .macOSRoman) { return text }
    if let text = try? String(contentsOf: url, encoding: .isoLatin1) { return text }
    return "[Could not read file as text]"
}

func extractText(from path: String) -> String {
    let url = URL(fileURLWithPath: path)
    let raw: String
    switch fileCategory(for: path) {
    case .pdf:          raw = extractPDF(from: url)
    case .image:        raw = extractImageOCR(from: url)
    case .richDocument: raw = extractRichDocument(from: url)
    case .plainText:    raw = extractPlainText(from: url)
    }
    return sanitizeText(raw)
}

// MARK: - Combine Text

func combineTexts(from paths: [String]) -> String {
    var sections: [String] = []
    for path in paths {
        let filename = URL(fileURLWithPath: path).lastPathComponent
        let text = extractText(from: path)
        sections.append("--- \(filename) ---\n\(text)")
    }
    return sections.joined(separator: "\n\n")
}

// MARK: - AppKit Window

class AppDelegate: NSObject, NSApplicationDelegate {
    let combinedText: String
    var window: NSWindow!

    init(text: String) {
        self.combinedText = text
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let screen = NSScreen.main?.visibleFrame else {
            fputs("No screen available\n", stderr)
            NSApplication.shared.terminate(nil)
            return
        }

        let width = screen.width * 0.7
        let height = screen.height * 0.8
        let x = screen.origin.x + (screen.width - width) / 2
        let y = screen.origin.y + (screen.height - height) / 2

        window = NSWindow(
            contentRect: NSRect(x: x, y: y, width: width, height: height),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Extracted Text"
        window.isReleasedWhenClosed = false

        let scrollView = NSScrollView(frame: window.contentView!.bounds)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false

        let textView = NSTextView(frame: scrollView.contentView.bounds)
        textView.autoresizingMask = [.width]
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textContainerInset = NSSize(width: 16, height: 16)
        textView.string = combinedText
        textView.textContainer?.widthTracksTextView = true
        textView.isHorizontallyResizable = false

        scrollView.documentView = textView
        window.contentView = scrollView

        // Close on Escape key
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 {
                NSApplication.shared.terminate(nil)
                return nil
            }
            return event
        }

        // Close button terminates the app
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { _ in
            NSApplication.shared.terminate(nil)
        }

        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}

// MARK: - Main

let args = Array(CommandLine.arguments.dropFirst())
guard !args.isEmpty else {
    fputs("Usage: extract-text <file1> [file2] ...\n", stderr)
    exit(1)
}

let combinedText = combineTexts(from: args)

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let delegate = AppDelegate(text: combinedText)
app.delegate = delegate
app.run()
