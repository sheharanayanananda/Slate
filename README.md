# Slate

Slate is a modern, intuitive, and intelligent note-taking application built exclusively for iOS using Swift and SwiftUI. It leverages local database persistence, hardware-secured credential storage, and an asynchronous language model pipeline with on-device computer vision and document processing.

---

## Core Features

### Rich Text & Markdown Outliner
* **Custom UIKit Text Engine Bridge**
  Uses a custom SwiftUI representable wrapper (`NativeTextView`) around UIKit's `UITextView` (`SlateTextView`) to enable precise typography controls, custom paragraph spacing, and custom cursor layouts.
* **Interactive Checklists**
  Converts standard Markdown checkbox syntax (`- [ ]` and `- [x]`) into interactive checkbox attachments using custom `NSTextAttachment` objects. Users can tap directly on the checklists inside the editor to toggle task completion, which automatically serializes and updates the raw note body in real-time.
* **Formatting Toolbar**
  A custom keyboard accessory toolbar provides formatting options including checklists, bullet lists, numbered lists, text formatting modifiers, and list indentation levels.
* **Layout Safeguards**
  Utilizes layout state monitoring flags within the text view coordinator to prevent recursive layout and selection loops, guaranteeing stability when loading or editing heavily styled rich-text notes.

### AI Note Structuring
* **Smart Organizer**
  A toolbar utility powered by the user's selected language model (defaulting to gemma4:31b) that cleans up unstructured notes, formats action items into checklists, corrects spelling and grammar, and structures the text into a clean, logical outline.
* **Skeleton Loader Interface**
  Displays a pulsing, wireframe skeleton interface in place of the text editor while the AI compiles and structures the note in the background.
* **Typewriter Presentation**
  Renders the organized AI output using a line-by-line typewriter animation as it populates the editor canvas, coupled with haptic selection feedback.

### Local Persistence & Security
* **Natively Persistent Database**
  Implements local, transaction-safe storage for notes using Apple's modern SwiftData framework. Notes are automatically sorted chronologically in reverse order (newest first).
* **Hardware-Secured Credentials**
  Stores and encrypts Ollama API keys on-device using Apple's Keychain Services with secure accessibility flags (accessible after first device unlock), keeping credentials separate from UserDefaults.

### Share and Export
* **Rich Text (RTF) Export**
  Exports formatted text documents to Mail, Messages, or Apple Notes, keeping custom styling and checklist states intact.
* **PDFKit Document Generation**
  Renders note titles, styled content, and checkbox selections into standard A4 PDF documents using PDFKit and UIGraphicsPDFRenderer.
* **Plain Text Export**
  Compiles and saves notes into standard .txt files.
* **Swipe Actions**
  Accessible via left-swipe (to share and export) and right-swipe (to delete) actions on any note list entry.

### Visual Scanner (Smart Lens)
* **VisionKit Document Scanner**
  Integrates VisionKit's VNDocumentCameraViewController to automatically crop, perspective-correct, and enhance document captures.
* **On-Device Vision Analysis**
  Performs two-stage local preprocessing using Apple's Vision framework:
  * *Text Recognition (OCR)*: Extracts raw text content from the document image.
  * *Image Classification*: Identifies objects and scenes in the image to provide additional context.
* **Contextual Note Synthesis**
  Combines the extracted OCR text and visual object classifications, passing them to the selected language model to generate structured Markdown notes with titles, summaries, key details, action items, and searchable hashtags.
* **Low-OCR Fallback**
  If the captured image has little or no text (e.g. photos of scenes or physical objects), the LLM synthesizes a note describing the visual scene based on on-device classification labels.

### Animated Side Drawer Settings
* **Slide Transition**
  The settings drawer is entirely button-driven and transition-animated. Tapping the gear icon on the main toolbar slides the settings panel in from the left using a spring-driven horizontal offset transition, and tapping the back chevron button slides it back out of view. No gesture recognizers are used for navigation.

### Product Roadmap
* **Scribe**
  Voice-command dictation and intelligent note structuring (Coming Soon).
* **Web Clipper**
  Extract clean note summaries and key findings from webpage URLs (Coming Soon).

### Demo Mode
* **Promotional Notes**
  Enabling Demo Mode pre-loads 5 styled promotional slates into the database to showcase checklist interactions, export features, and editor formatting.
* **Simulated Tools**
  Presents simulated tool cards for coming soon features in the Tools tab (Web Clipper, Concept Canvas, Smart Dictation, and Auto-Organizer) and routes all cards to generic preview sheets.

---

## Requirements

- Xcode 15.0 or later
- iOS 17.0 or later
- A device or simulator with camera permissions enabled (for Smart Lens)
- Active network connection (for cloud-based selected AI features)

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
   The application communicates with the selected model endpoint using the credentials configured in the settings panel. Enter your API Key securely inside the app Settings.

4. **Build and Run**:
   - Choose a target device (e.g. an iPhone running iOS 17+ or a simulator).
   - Press `⌘ + R` or click the Play button in Xcode to compile and launch.

---

## Testing

The project includes test targets to verify core functionality:
- **SlateTests**: Verifies models, text conversion, and data manipulation.
- **SlateUITests**: Automated interface tests for note creation and screen flows.

Run tests using `⌘ + U` in Xcode or via the Test navigator.

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

For commercial licensing agreements, custom integrations, or enterprise inquiries, please contact the author.
