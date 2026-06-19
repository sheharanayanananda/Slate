# Slate

Slate is a modern, intuitive, and intelligent notes application built exclusively with Swift and SwiftUI for iOS. It combines rich-text capabilities, local persistence, advanced sharing features, and smart visual AI intelligence to redefine how you capture ideas.

---

## Core Features

### Rich Text & Markdown Editor
* **Custom Text Editor**
  Allows full styling of notes (bold, italic, underline, custom fonts, and colors) through a custom bridged text view.
* **Interactive Checklists**
  Converts standard Markdown checkbox syntax (`- [ ]` and `- [x]`) into interactive checkbox attachments. Users can tap directly on checkboxes in the note editor to toggle task completion.
* **Dual Format Encoding**
  Saves styled notes as Base64-encoded Rich Text Format (RTF) strings (prefixed with `rtf:`) while maintaining fallback parsing for standard inline Markdown.

### AI-Powered Note Organization
* **Smart Structure Utility**
  A toolbar button powered by Gemma 3 (27B) that restructures rough or messy notes, improves text layout, resolves spelling/grammar errors, and automatically formats action plans into checklists.
* **Context-Aware Animations**
  * *Pulsing Skeleton Loader*: Replaces the editing canvas with a breathing visual wireframe placeholder during model request processing.
  * *Typewriter Animation*: Fades in completed AI notes line-by-line for a smooth visual transition.

### Local Data Persistence
* **Native SwiftData Integration**
  Uses Apple's modern SwiftData framework for fast, transactional local storage.
* **Automatic Sorting**
  Keeps slates sorted chronologically with intuitive swipe-to-delete gesture integration.

### Sharing and Export Formats
* **Rich Text (RTF)**
  Exports fully formatted text documents to Messages, Mail, or native Apple Notes, keeping checklist selections intact.
* **Dynamic PDF Export**
  Generates standard US Letter size PDF documents on the fly with titles, formatted body text, and checklist status details using PDFKit.
* **Plain Text Export**
  Compiles and saves notes to clean `.txt` files.

### Smart Lens (Visual AI Assistant)
* **On-Device Preprocessing**
  Runs Vision APIs on captured images (OCR text recognition and object classification) to extract raw data before calling the cloud LLM.
* **Image Optimization**
  Resizes image assets and aligns orientations on-device to minimize payload size and latency.
* **Note Synthesis**
  Combines recognized text and labeled objects to generate contextual notes with summaries, bullet points, tags, and action items.
* **Visual Scene Fallback**
  If the target has no text (e.g., photos of objects or rooms), the AI synthesizes notes based on the classified visual contents.

### Product Roadmap
* **Transcribe**
  High-fidelity audio recording and transcription (Coming Soon)
* **Summarize**
  Interactive long-form note summarization (Coming Soon)

---

## Architecture & Project Structure

The project follows a clean, modular feature-based folder structure:

```
Slate/
├── App/
│   ├── SlateApp.swift          # App entrypoint and SwiftData model container initialization
│   └── ContentView.swift       # Tab navigation hub (Slate, Tools, and Create sheets)
├── Core/
│   ├── Models/
│   │   └── SlateModel.swift    # SwiftData Schema, RTF encoders, and Markdown parsers
│   └── API/
│       ├── OllamaClient.swift  # Network layer connecting to Gemma 3 model api
│       └── Secrets.swift       # Client API authentication credentials
├── Features/
│   ├── Slate/
│   │   ├── SlateTabView.swift  # Main Notes List with Swipe-to-Share / Swipe-to-Delete
│   │   └── Components/         # Sub-UI components (e.g., ShareSheet)
│   ├── Create/
│   │   ├── CreateTabView.swift # Note creation/editing interface
│   │   └── RichTextEditor.swift# Custom UIViewRepresentable UITextView for RTF editing
│   ├── Intelligence/
│   │   ├── IntelligenceTabView.swift # Visual tools menu (Smart Lens, Transcript, etc.)
│   │   └── Components/         # Sheets for Smart Lens, Summarize, Transcript, and CameraView
│   └── Settings/
│       └── SettingsTabView.swift # Settings panel displaying app info and theme assets
└── Shared/
    └── Utilities/
        ├── CameraViewController.swift # AVFoundation interface for high-performance capturing
        └── NoteSharingHelper.swift    # PDF creation, plain text compilation, and Rich Text builders
```

---

## Requirements

- **Xcode 15.0** or later
- **iOS 17.0** or later (required for SwiftData and modern SwiftUI APIs)
- A device or simulator with camera permissions enabled (for Smart Lens)
- Active internet connection (for cloud-based Ollama features)

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
   The application communicates with the Ollama endpoint using the credentials configured in `Secrets.swift`. Check `Slate/Core/API/Secrets.swift` to verify or update your bearer token.

4. **Build and Run**:
   - Choose a target device (e.g. an iPhone running iOS 17+ or a simulator).
   - Press `⌘ + R` or click the Play button in Xcode to compile and launch.

---

## Testing

The project includes test targets to verify core functionality:
- **SlateTests**: Verifies models, RTF conversion, and data manipulation.
- **SlateUITests**: Automated interface tests for note creation and screen flows.

Run tests using `⌘ + U` in Xcode or via the Test navigator.

---

## License

This project is proprietary and confidential. All rights are reserved by the copyright owner. See the [LICENSE](file:///Users/thinethshehara/Documents/Store/Projects/Slate/LICENSE) file for details.
