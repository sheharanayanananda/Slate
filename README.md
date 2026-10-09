# Slate Origin (V1)

Welcome to Slate Origin.

Slate Origin is the initial version of Slate, built to explore clean, distraction-free note-taking on iOS with smart document scanning and AI-assisted note organization. It saves everything locally on your device using SwiftData and connects to the Ollama Cloud API for intelligent features.

Further active development on Slate Origin has halted and this version is now retired. Slate Genesis on the v2 branch represents the future of the project, completely rebuilt from the ground up with streaming cloud AI chat and a hybrid block editor.

### Technical Highlights

#### Writing Canvas & Native Text Editor
* NativeTextView editor: A custom text canvas built on UITextView that supports standard Markdown formatting for headings, bold, italic, underline, strikethrough, and lists.
* Interactive checkboxes: Renders SF Symbol checkbox attachments for `- [ ]` and `- [x]` syntax. A surgical tap gesture recognizer uses glyph hit-testing so you can check and uncheck items directly in the text without disrupting your cursor position.
* Keyboard accessory toolbar: A floating capsule bar sitting above the virtual keyboard with one-tap controls for styling, checklists, bullet lists, numbered lists, and indentation.

#### AI Note Organization & Smart Lens
* Organize with AI: Tap the sparkles button to have Ollama Cloud analyze messy, unstructured notes. The editor measures your typed lines, displays an animated SkeletonView loading placeholder, and renders the structured Markdown line-by-line using a typewriter animation with haptic feedback.
* Smart Lens document scanner: Uses VisionKit (VNDocumentCameraViewController) to capture physical documents. On-device Vision OCR (VNRecognizeTextRequest) and scene classification (VNClassifyImageRequest) run in parallel, passing the extracted text and scene details to Ollama Cloud to generate structured Markdown notes.
* Background title generation: When saving an untitled note, a background task asks Ollama Cloud for a concise title without blocking the interface.

#### Architecture & System Integration
* Offline persistence: Notes are stored locally using SwiftData, automatically sorted in reverse chronological order.
* Secure key storage: Your Ollama API key is encrypted directly in Apple Keychain using the Security framework.
* Multi-format export: Share notes as adaptive Rich Text (RTF via a custom converter), A4 PDF files (rendered through PDFKit), or plain text.
* Zero third-party dependencies: Built entirely with native Apple frameworks (SwiftUI, SwiftData, UIKit, VisionKit, Vision, PDFKit, Security).

### App Layout

* Slate: Your note library with rich Markdown previews, swipe-to-delete, and multi-format sharing.
* New / Edit: The rich text editor with the floating formatting toolbar and AI organizer.
* Tools: Standalone utility hub housing the Smart Lens document scanner and an experimental Scribe voice dictation prototype with animated audio waveforms.
* Settings: A spring-animated slide-out panel for entering and validating your Ollama API key.

### Requirements

* Xcode 16.0 or later
* iOS 26.0 or later
* iPhone simulator or physical device (camera access required for Smart Lens)
* Active internet connection for Ollama Cloud API requests
* An Ollama account and API key from ollama.com

### Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/sheharanayanananda/Slate.git
   cd Slate
   ```

2. Open `Slate.xcodeproj` in Xcode.
3. Select an iPhone target (physical device or iOS 26 simulator) and run (`Cmd + R`).
4. Tap the gear icon in the top-left of the Slate tab to open the slide-out Settings panel.
5. Paste your Ollama API key. The key is validated live and saved securely to the Apple Keychain.
6. Optional: Select your preferred model from the dropdown (defaults to `gemma4:31b`), or turn on Demo Mode to load sample notes.

### License

Slate Origin Source-Available License. Free for personal inspection and educational evaluation; commercial use is prohibited without permission. See LICENSE for details.
