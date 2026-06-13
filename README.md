# Slate

Slate is a modern, intuitive, and intelligent notes application built exclusively with Swift and SwiftUI for iOS. It combines rich-text capabilities, local persistence, advanced sharing features, and smart visual AI intelligence to redefine how you capture ideas.

---

## Features

### Rich Text & Markdown Editing
- **Interactive Editor**: Write and style notes with bold, italic, underline, and color attributes using a custom-bridged rich text editor.
- **Dual Support**: Seamlessly parses and stores standard Rich Text Format (RTF) data encoded in Base64 (prefixed with "rtf:"), while offering automatic fallback parsing for standard Markdown notes.

### SwiftData Persistence
- Fast, reliable, and native local database persistence using Apple's modern SwiftData framework.
- Chronological automatic sorting of slates, with responsive list views and swipe-to-delete.

### Versatile Note Sharing & PDF Export
- Swiping right on any note launches a share sheet offering three export formats:
  - **Rich Text (RTF)**: Automatically formatted RTF source shared directly to Messages, Mail, or native Apple Notes.
  - **PDF Document**: On-the-fly rendering of note titles and styled content into standard US Letter PDF documents using PDFKit and UIGraphicsPDFRenderer.
  - **Plain Text**: Clean export as a standard .txt file.

### Smart Lense (AI Visual Intelligence)
- Capture any photo using the in-app camera interface.
- Send the visual context to an Ollama-compatible endpoint powered by the Gemma 3 (27B) model ("gemma3:27b-cloud").
- The AI deduces the implicit intent behind the image (such as noting low inventory from a photo of a food item, suggesting a repair for a broken device, or extracting receipts) and auto-generates a structured Markdown note containing:
  - Descriptive title and category tags
  - Executive summary of the situation
  - List of key observations/details
  - Actionable next steps and searchable hashtags

### Advanced Tools (Roadmap)
- **Transcript**: Audio-to-text conversion (Coming Soon)
- **Summarize**: Interactive long-form summarization (Coming Soon)

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
│   │   ├── IntelligenceTabView.swift # Visual tools menu (Smart Lense, Transcript, etc.)
│   │   └── Components/         # Sheets for Smart Lense, Summarize, Transcript, and CameraView
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
- A device or simulator with camera permissions enabled (for Smart Lense)
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
