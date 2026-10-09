# Slate Genesis (V2)

Welcome to Slate Genesis.

Slate Genesis is my take on what note-taking should look like in the modern AI era: minimal, automated, and built around a familiar chat interface with emerging GenUI capabilities.

The original version on the main branch, Slate Origin, focused on offline document scanning and standard notes. With Genesis, I rebuilt the app from the ground up on the v2 branch to remove friction from capturing and organizing knowledge. Instead of manually typing and reformatting everything, you can brainstorm with cloud AI, extract structured notes with a tap, and write on a distraction-free canvas.

### The Editor: Regular Content vs Special Blocks

One of the biggest problems with Markdown editors is that they are often intimidating for casual users and clunky when dealing with complex formatting. In Genesis, I separated note content into two distinct tiers so anyone, regardless of technical background, can write comfortably:

* Regular Content: Everyday writing that feels natural to all users. Paragraphs, headings, bullet lists, numbered lists, and interactive checklists behave like a familiar notes app. You can write your thoughts without needing to know or think about Markdown syntax.
* Special Blocks: Complex elements isolated into clean, self-contained visual cards. Special blocks include:
  - Code blocks with native language syntax highlighting
  - Multi-column tables with horizontal scrolling
  - LaTeX mathematical equations rendered offline
  - Alert callouts (Note, Tip, Warning, Caution, and Important)
  - Blockquotes and horizontal dividers

This design keeps you focused on writing. You never have to deal with table pipes or broken brackets while typing; special blocks render as clean visual cards. Tapping a block highlights it with a focus ring, and pressing backspace removes it cleanly via a hidden 1x1 proxy responder.

At the moment, you can only create or adjust these blocks through Slate AI in chat, as direct manual editing on the note canvas is not yet supported. I am researching ways to introduce direct editing and advanced formatting without making the editor feel complex, so stay tuned.

### Other Engineering Highlights

* Offline KaTeX math: Equations render completely offline using bundled KaTeX scripts and fonts inside a local WKWebView, using a WebKit script handler to auto-size the view dynamically.
* Bidirectional serializer: The editor converts Markdown into rich attributed text and serializes everything back into clean Markdown on save.
* Turn chat into notes: Convert any AI response into a permanent note with one tap. It extracts a clean, emoji-free title, links the note ID back to the message, and saves directly to SwiftData.
* Ollama Cloud streaming: Streams responses token-by-token using three presets (Flash for quick answers, Creative for brainstorming, and Pro for deep reasoning and code). Requests continue in the background if you leave the app.
* Pure-Swift document ingestion: Attach PDFs, DOCX, and XLSX files. They are decompressed and parsed using Apple's Compression framework and XML SAX parsing without any third-party libraries.
* Zero external packages: The entire project is built strictly using native Apple frameworks (SwiftUI, SwiftData, UIKit, WebKit, VisionKit, Security).

### App Layout

* Home: Your note collection backed by SwiftData, with Markdown previews, swipe-to-delete, and export options (PDF, RTF, plain text).
* Editor: The hybrid block editor with a dedicated toolbar for styling, lists, and indents.
* Slate AI: Full-screen chat workspace supporting multi-session history, camera and document scanning, and file attachments.

I am currently working on GenUI interactive checkboxes directly inside AI chat responses.

### Getting Started

To run Slate Genesis, you will need:
* Xcode 16.0+
* iOS 26.0 or later
* An Ollama account and API key from ollama.com

1. Clone the repository and switch to the v2 branch:
   ```bash
   git clone https://github.com/sheharanayanananda/Slate.git
   cd Slate
   git checkout v2
   ```

2. Open `Slate.xcodeproj` in Xcode and run on an iOS 26 simulator or device (`Cmd + R`).
3. Open Settings from the Home tab and enter your Ollama API key.

### License

Slate Proprietary Source-Available License. You are welcome to inspect, clone, and evaluate the code for personal and educational purposes. Commercial use is prohibited without permission. See LICENSE for details.
