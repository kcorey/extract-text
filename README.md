# extract-text

A macOS command-line tool that extracts text from documents and images and displays it in a native scrollable window. Supports PDFs, images (via OCR), rich documents, and plain text. Comes with an Automator Quick Action for Finder right-click integration.

## Requirements

- macOS (uses Apple frameworks: AppKit, Vision, PDFKit)
- Swift compiler — either Xcode or the Command Line Tools package:
  ```
  xcode-select --install
  ```

No third-party dependencies.

## Compilation

```bash
./build.sh
```

This runs `swiftc -O -o extract-text ExtractText.swift` and produces the `extract-text` binary in the project directory.

## Installation (Finder Quick Action)

```bash
./install.sh
```

This builds the binary and installs the Automator workflow to `~/Library/Services/Extract Text.workflow`, making it available as a Quick Action in Finder.

If "Extract Text" doesn't appear in the right-click menu after installation:

- Open **System Settings → Privacy & Security → Extensions → Finder Extensions** and ensure "Extract Text" is enabled
- Or log out and log back in

## Usage

### Command line

```bash
./extract-text file1.pdf
./extract-text image.png document.docx notes.txt
```

Pass one or more files. When multiple files are given, they are combined into a single view separated by `--- filename ---` headers.

The extracted text opens in a native macOS window (70% of screen width, 80% of screen height). Text is selectable but not editable. Press **Escape** or close the window to quit.

### Finder Quick Action

After running `./install.sh`:

1. Select one or more files in Finder
2. Right-click → **Quick Actions → Extract Text**

## Supported Formats

| Category | Extensions | Method |
|---|---|---|
| PDF | `.pdf` | PDFKit text layer |
| Images | `.png` `.jpg` `.jpeg` `.tiff` `.tif` `.heic` `.heics` `.webp` `.gif` `.bmp` `.jp2` `.jxl` | Vision OCR |
| Rich documents | `.docx` `.doc` `.odt` `.rtf` `.rtfd` | NSAttributedString |
| Plain text | everything else | UTF-8 → macOS Roman → ISO Latin-1 |

Unrecognised extensions are treated as plain text.

## Gotchas & Warnings

**Hardcoded path in the workflow**

The Automator workflow (`Extract Text.workflow/Contents/document.wflow`) hardcodes the binary path:

```
/Volumes/PS2000W/Developer/reader/extract-text
```

If you clone the repo to a different location, the Quick Action will fail silently. Fix it one of two ways:

- Edit the `COMMAND_STRING` in `document.wflow` to match your actual path before running `install.sh`, or
- Open the installed workflow in Automator (`~/Library/Services/Extract Text.workflow`) and update the shell script path there.

**Scanned / image-only PDFs**

PDF extraction uses PDFKit's embedded text layer. A PDF that is purely a scanned image with no text layer will return `[No text found in PDF]`. To extract text from a scanned PDF, save each page as an image first and pass those image files instead.

**OCR accuracy**

Image OCR uses the Vision framework at `.accurate` recognition level with language correction enabled. Quality depends on image resolution and clarity; low-resolution or heavily stylised text may produce poor results.

**Gatekeeper**

The compiled binary is not code-signed. On first run via the Finder Quick Action, macOS may block it. If this happens, go to **System Settings → Privacy & Security** and allow it to run, or clear the quarantine attribute:

```bash
xattr -d com.apple.quarantine extract-text
```

**No Dock icon**

The app uses the `.accessory` activation policy, so it does not appear in the Dock or Command-Tab switcher. It will appear briefly in the menu bar when active.

**GIF and WebP OCR**

Animated GIFs and WebP files are decoded as static images (first frame). The Vision framework will attempt OCR on whatever pixel data it receives, which may produce nonsense for non-document images.

## Project Structure

```
ExtractText.swift          Source code
build.sh                   Compiles the binary
install.sh                 Builds and installs the Automator workflow
Extract Text.workflow/     Automator Quick Action package
extract-text               Compiled binary (not in git)
```
