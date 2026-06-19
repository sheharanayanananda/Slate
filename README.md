# Slate

Slate is an autonomous AI agentic knowledge workspace built exclusively for iOS using Swift and SwiftUI. It combines a distraction-free rich-text editor and local persistence with a conversational AI agent interface capable of auto-generating notes, executing actions, and connecting to external platforms (Gmail, Slack, Calendar) via voice and chat.

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

### Conversational AI Agent Tab
* **Interactive Chat Interface**
  A central command dashboard featuring a message input field and a mic option for ambient voice interactions. Type commands or talk directly to Slate (e.g., "Summarize my tasks" or "Create a draft note from my last meeting details").
* **Autonomous Execution**
  The agent interprets your requests to perform background tasks, synthesize notes, and update action items on your behalf.
* **Platform Connections**
  Integrates securely with external platforms (Gmail, Slack, Google Calendar, Jira) to retrieve context, write emails, sync meetings, and delegate tasks without leaving the app.

### Settings
* **Slide Transition**
  Tapping the gear icon on the main toolbar slides the settings panel in from the left, and tapping the back chevron button slides it back out of view. No gesture recognizers are used for navigation.

### Product Roadmap (Slate V2)
* **Agent Conversational UI**
  The new dedicated Agent tab featuring chat bubbles, mic button, and live status feedback as the agent works.
* **Platform Integration Hub**
  OAuth setup and APIs connecting the agent directly to Google Workspace (Gmail, Calendar), Slack, and developer portals.
* **Proactive Context Graph**
  Continuous background semantic indexing using local vector storage to suggest relevant notes, messages, and threads inline as you write.
* **Scribe V2 (Voice Agent)**
  Ambient voice dictation that interprets conversational instructions (e.g., "Add a note about meeting John next Wednesday and email him the summary").

---

## Architecture & Project Structure

The project follows a clean, modular feature-based folder structure:

```
Slate/
├── App/
│   ├── SlateApp.swift          # App entrypoint and SwiftData model container initialization
│   └── ContentView.swift       # Tab navigation hub, settings transition, and AI agent pipeline
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
│   ├── Agent/
│   │   ├── AgentTabView.swift  # Conversational chat & voice AI Agent tab
│   │   ├── PlatformConnector.swift # Connections for external APIs (Gmail, Slack, etc.)
│   │   └── Components/         # Chat message elements, waveforms, and visual feedback
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
- A device or simulator with microphone permissions enabled (for voice features)
- Active internet connection (for cloud-based features)

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

This project is proprietary and confidential. All rights are reserved by the copyright owner. Personal, educational, and evaluation use is permitted. Commercial use, redistribution, or marketplace publication is strictly prohibited without a separate Commercial License. 

To purchase a Commercial License or discuss enterprise use cases, please contact the author:
- **Email:** sheharanayanananda@gmail.com
- **LinkedIn:** [Thineth Nayanananda](https://www.linkedin.com/in/thineth-nayanananda-54815b228/)

See the [LICENSE](file:///Users/thinethshehara/Documents/Store/Projects/Slate/LICENSE) file for the full terms.
