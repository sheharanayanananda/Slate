# Slate

Slate is a simple, smart note-taking app for iOS built with Swift and SwiftUI. It saves notes offline on your device, encrypts your keys, and lets you scan documents to create organized notes using AI.

---

## Features

### Rich Text Editor
* **Writing Canvas**
  Write and format notes easily. The editor supports bold, italic, underline, strikethrough, and paragraph spacing.
* **Checklists**
  Use standard markdown (`- [ ]` and `- [x]`) for lists. You can tap directly on the checkboxes inside the editor to check or uncheck items. The note saves automatically.
* **Keyboard Toolbar**
  A formatting bar sits above your keyboard so you can quickly style text, make lists, or indent items with one tap.
* **Typing Safeguards**
  Hidden safeguards keep the editor smooth, responsive, and stable while you write.

### AI Note Organizer
* **Smart Organizer**
  Tap the sparkles button in the toolbar. The AI cleans up messy notes, fixes spelling mistakes, and organizes your text into a clean outline.
* **Skeleton Loading Screen**
  Shows a loading screen while the AI structures your note in the background.
* **Typewriter Effect**
  Renders the AI's organized output line-by-line with soft haptic feedback.

### Saving Notes Offline & Security
* **Offline Saving**
  Saves your notes directly on your device using SwiftData. Notes are automatically sorted by date (newest first).
* **Secure API Keys**
  Encrypts and stores your API keys safely on your device using Apple Keychain so they stay private.

### Sharing & Exporting
* **Export Options**
  Export your notes as Rich Text (RTF), A4 PDF files (using PDFKit), or plain text (.txt) files.
* **Quick List Actions**
  Swipe left on any note in the list to share or export it. Swipe right to delete.

### Smart Lens (Camera Scan)
* **Document Scan**
  Scan paper documents, receipts, or whiteboards using your camera with VisionKit. The app crops and cleans up the image automatically.
* **Text & Object Detection**
  Recognizes text in the scan and identifies objects or scenes using Apple's Vision framework.
* **AI Note Creator**
  Uses the scanned text and image details to generate structured markdown notes. If the scan has no text, the AI describes the scene instead.

### Settings Panel
* **Slide Transition**
  Tap the gear button on the toolbar to slide the settings panel in from the left. Tap the back button to slide it away.

### Product Roadmap
* **Scribe**
  Speak to the app to dictate thoughts and let the AI structure your note (Coming Soon).
* **Web Clipper**
  Extract summaries and key points from webpage links (Coming Soon).

### Demo Mode
* **Sample Notes**
  Turn on Demo Mode in settings to load 5 pre-made notes that showcase lists, formats, and sharing.
* **Simulated Tools**
  Presents mockup cards in the Tools tab for upcoming features.

---

## Requirements

- Xcode 15.0 or later
- iOS 17.0 or later
- Camera permissions enabled (for Smart Lens)
- Internet connection (for AI features)

---

## Getting Started

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/sheharanayanananda/Slate.git
   cd Slate
   ```

2. **Open the Project**:
   Double-click `Slate.xcodeproj` to open it in Xcode.

3. **Set Up API Keys**:
   The app connects to your selected AI model using the API key in settings. Enter your key securely in the app Settings screen.

4. **Build and Run**:
   - Choose a target device (like an iPhone or simulator).
   - Press `⌘ + R` or click the Play button in Xcode to run.

---

## Testing

The project includes test targets to verify core functionality:
- **SlateTests**: Tests text formatting and data saving.
- **SlateUITests**: Tests note creation and screen flows.

Run tests using `⌘ + U` in Xcode.

---

## License

This project is licensed under the Slate Proprietary Source-Available and Commercial Restriction License - see the [LICENSE](LICENSE) file for details.
