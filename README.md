# Slate

Slate is a modern, intuitive, and intelligent note-taking application built exclusively for iOS using Swift and SwiftUI. It bridges advanced rich-text formatting, local database persistence, and secure credential storage with visual AI intelligence and document scanning.

---

## Core Features

### Rich Text & Markdown Editor
* **Custom Text View Integration**
  Uses a custom SwiftUI representable wrapper around UIKit's UITextView (NativeTextView wrapping SlateTextView) to enable fine-grained styling controls. Write and format notes with bold, italic, underline, strikethrough, paragraph spacing, and custom font weights.
* **Interactive Checklists**
  Converts standard Markdown checkbox syntax (`- [ ]` and `- [x]`) into interactive checkbox attachments using custom NSTextAttachment objects. Users can tap directly on the checkboxes inside the editor (NativeTextView) to toggle task completion. The note's raw markdown text is serialized and updated in real-time.
* **Formatting Toolbar**
  A custom keyboard accessory toolbar provides formatting options including checklists, bullet lists, numbered lists, text formatting modifiers, and list indentation levels.
* **Layout Safeguards**
  Utilizes layout state monitoring flags to prevent recursive layout and selection loops, guaranteeing stability when loading or editing heavily styled rich-text notes.

### AI-Powered Note Organization
* **Smart Structuring**
  A toolbar utility powered by the user-selected Gemma model (defaulting to gemma4:31b) that cleans up unstructured notes, formats action items into checklists, corrects spelling and grammar, and structures the text into a clean, logical outline.
* **Pulsing Skeleton Loader**
  Displays a pulsing, wireframe skeleton interface in place of the text editor while the AI compiles and structures the note in the background.
* **Typewriter Presentation**
  Renders the organized AI output using a line-by-line typewriter animation as it populates the editor canvas.

### Local Data Persistence & Credentials
* **SwiftData Storage**
  Implements local, transaction-safe storage for notes using Apple's modern SwiftData framework. Notes are automatically sorted chronologically in reverse order (newest first).
* **Secure Keychain Integration**
  Stores and encrypts Ollama API keys on-device using Apple's Keychain Services with secure accessibility flags (accessible after first device unlock), keeping credentials separate from UserDefaults.

### Sharing Options
* **Rich Text (RTF)**
  Exports formatted text documents to Mail, Messages, or Apple Notes, keeping custom styling and checklist states intact.
* **On-the-fly PDF Generation**
  Renders note titles, styled content, and checkbox selections into standard A4 PDF documents using PDFKit and UIGraphicsPDFRenderer.
* **Plain Text Export**
  Compiles and saves notes into standard .txt files.
* **Swipe Actions**
  Accessible via left-swipe (to share and export) and right-swipe (to delete) actions on any note list entry.

### Smart Lens
* **Document Scanner**
  Integrates VisionKit's VNDocumentCameraViewController to automatically crop, perspective-correct, and enhance document captures.
* **Local Preprocessing**
  Performs two-stage local preprocessing using Apple's Vision framework:
  * *Text Recognition (OCR)*: Extracts raw text content from the document image.
  * *Image Classification*: Identifies objects and scenes in the image to provide additional context.
* **Contextual Note Synthesis**
  Combines the extracted OCR text and visual object classifications, passing them to the user-selected cloud model to generate structured Markdown notes with titles, summaries, key details, action items, and searchable hashtags.
* **Low-OCR Fallback**
  If the captured image has little or no text (e.g. photos of scenes or physical objects), the LLM synthesizes a note describing the visual scene based on on-device classification labels.

### Settings
* **Slide Transition**
  Tapping the gear icon on the main toolbar slides the settings panel in from the left, and tapping the back chevron button slides it back out of view. No gesture recognizers are used for navigation.

### Product Roadmap
* **Transcribe**
  High-fidelity audio recording and transcription (Coming Soon).
* **Web Clipper**
  Extract clean note summaries and key findings from webpage URLs (Coming Soon).

### Demo Mode
* **Promotional Notes**
  Enabling Demo Mode in settings pre-loads 5 styled promotional slates into the database to showcase checklist interactions, export features, and editor formatting.
* **Simulated Tools**
  Presents simulated tool cards for coming soon features in the Tools tab (Web Clipper, Concept Canvas, Smart Dictation, and Auto-Organizer) and routes all cards to generic preview sheets.

---

## Architecture & Project Structure

The project follows a clean, modular feature-based folder structure:

```
Slate/
├── App/
│   ├── SlateApp.swift          # App entrypoint and SwiftData model container initialization
│   └── ContentView.swift       # Tab navigation hub, settings transition, and AI scanner pipeline
├── Core/
│   ├── Models/
│   │   └── SlateModel.swift    # SwiftData Schema, RTF encoders, and Markdown parsers
│   └── API/
│       └── OllamaClient.swift  # Network layer connecting to Ollama API
├── Features/
│   ├── Slate/
│   │   ├── SlateTabView.swift  # Main Notes List with Swipe-to-Share / Swipe-to-Delete
│   │   └── Components/         # Sub-UI components (e.g., ShareSheet)
│   ├── Create/
│   │   ├── CreateTabView.swift # Note creation/editing interface
│   │   └── Components/
│   │       └── NativeTextView.swift # Custom bridged UITextView, NSTextAttachment, and Markdown parser
│   ├── Tools/
│   │   ├── ToolsTabView.swift  # Feature cards list and demo tool configurations
│   │   ├── ToolType.swift      # Enum representing available utilities
│   │   └── Components/         # Sheets for Smart Lens, Transcribe, and custom ToolCard
│   └── Settings/
│       ├── SettingsView.swift  # Key configurations and model settings
│       └── SettingsViewModel.swift # Keychain credentials validation and model fetching
└── Shared/
    └── Utilities/
        ├── KeychainHelper.swift # Secure Keychain operations using SecItem API
        ├── MarkdownToRTFConverter.swift # Rich Text converter for standard markdown text
        └── NoteSharingHelper.swift # PDF creation, plain text compilation, and Rich Text builders
```

---

## Requirements

- **Xcode 15.0** or later
- **iOS 17.0** or later (required for SwiftData and TextKit 2 APIs)
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
   The application communicates with the Ollama endpoint using the credentials configured in the settings panel. Enter your Ollama API Key securely inside the app Settings.

4. **Build and Run**:
   - Choose a target device (e.g. an iPhone running iOS 17+ or a simulator).
   - Press `⌘ + R` or click the Play button in Xcode to compile and launch.

---

## License

This project is proprietary and confidential. All rights are reserved by the copyright owner. The Software is source-available solely for personal, educational, and evaluation purposes. 

### Key Restrictions:
* **No Commercial Use**: Any commercial use, business operations, or integration into proprietary products requires a separate Commercial License.
* **No SaaS or Cloud Hosting**: Deploying the software to offer its features or APIs as a service (SaaS) to third parties is strictly prohibited.
* **No Marketplace Publication**: You may not publish or distribute the application on public app marketplaces (such as the Apple App Store).
* **No AI Training Ingestion**: Utilizing the source code, assets, or design systems for training or fine-tuning artificial intelligence/machine learning models is strictly forbidden.
* **Corporate & Organizational Exclusion**: Personal/educational evaluation grants do not apply to commercial entities, organizational operations, or internal business testing.
* **Design Protection**: Replicating or copying the visual design layouts, transitions, or assets of this application is prohibited.

For commercial licensing agreements, custom integrations, or enterprise inquiries, please review the [LICENSE](file:///Users/thinethshehara/Documents/Store/Projects/Slate/LICENSE) file or contact the author.
