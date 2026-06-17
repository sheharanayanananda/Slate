//
//  CreateTabView.swift
//  Slate
//

import SwiftUI
import SwiftData

struct CreateTabView: View {
    @State private var text: String = ""
    
    @Binding var editingNote: SlateModel?
    @Binding var activeTab: ContentView.TabIdentifier

    @Environment(\.modelContext) private var context
    @State private var showEmptyWarning: Bool = false
    @State private var isOrganizing: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert: Bool = false
    @State private var wasTitlePreGenerated: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            NativeTextView(text: $text)
        }
        .onAppear {
            if let note = editingNote {
                text = note.desc
                wasTitlePreGenerated = !note.title.isEmpty && note.title != "New Note"
            } else {
                wasTitlePreGenerated = false
            }
        }
        .onChange(of: editingNote) { _, newValue in
            if let note = newValue {
                text = note.desc
                wasTitlePreGenerated = !note.title.isEmpty && note.title != "New Note"
            } else {
                text = ""
                wasTitlePreGenerated = false
            }
        }
        .navigationTitle(editingNote == nil ? "New Note" : "Edit Note")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", systemImage: "xmark", role: .cancel) {
                    cancel()
                }
            }
                        
            ToolbarItem(placement: .primaryAction) {
                if isOrganizing {
                    ProgressView()
                } else {
                    Button {
                        organizeNoteWithAI()
                    } label: {
                        Label("Organize with AI", systemImage: "sparkles")
                    }
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", systemImage: "checkmark", role: .confirm) {
                    saveNote()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .alert("Empty Note", isPresented: $showEmptyWarning) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Can't save an empty note.")
        }
        .alert("AI Organizer Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred.")
        }
    }
    
    private func saveNote() {
        let trimmedDesc = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedDesc.isEmpty {
            showEmptyWarning = true
            return
        }
        
        let targetNote: SlateModel
        let initialTitle = generateInitialTitle(from: trimmedDesc)
        
        if let note = editingNote {
            note.desc = trimmedDesc
            // Only update title if it's currently empty, or if we want to overwrite it. 
            // We'll update the title. Wait, if it already had a title, maybe we shouldn't overwrite it.
            // But let's just generate a new one if it's essentially default. For now, let's always regenerate or only if empty.
            if note.title.isEmpty {
                note.title = initialTitle
            }
            targetNote = note
            if targetNote.modelContext == nil {
                context.insert(targetNote)
            }
        } else {
            targetNote = SlateModel(title: initialTitle, desc: trimmedDesc)
            context.insert(targetNote)
        }
        
        // Capture id to fetch safely in background if needed, but SwiftData objects aren't thread safe.
        // Actually, updating the object on the main thread is safer. 
        // The background generation will yield a string, and we'll update targetNote on MainActor.
        
        if !wasTitlePreGenerated {
            Task {
                await generateTitleInBackground(for: targetNote, content: trimmedDesc)
            }
        }
        
        reset()
        activeTab = .notes
    }
    
    private func generateInitialTitle(from text: String) -> String {
        let words = text.split(whereSeparator: { $0.isWhitespace || $0.isNewline })
        let firstThree = words.prefix(3).joined(separator: " ")
        return firstThree.isEmpty ? "New Note" : firstThree
    }
    
    private func generateTitleInBackground(for note: SlateModel, content: String) async {
        do {
            let client = OllamaClient()
            let systemPrompt = """
            You are a helpful assistant. Provide a highly concise, suitable title (maximum 4 words) for the following note content. 
            Respond ONLY with the title, without any quotes or punctuation around it.
            """
            let title = try await client.generate(
                prompt: content,
                system: systemPrompt
            )
            let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedTitle.isEmpty {
                await MainActor.run {
                    note.title = trimmedTitle
                }
            }
        } catch {
            print("Failed to generate title in background: \(error.localizedDescription)")
        }
    }
    
    private var aiSystemPrompt: String {
        """
        You are an expert note organizer. Your task is to analyze the content and context of the provided note and reorganize/summarize it to make it highly readable, clear, structured, and easy to use.
        
        CRITICAL: You must only use the following Markdown formatting features supported by our editor:
        1. Checklists: `- [ ] Item` (use for todos, tasks, shopping items, checklists)
        2. Bullet points: `- Item` (use for lists, details, brainstorms)
        3. Numbered lists: `1. Item` (use for sequences, steps, recipes)
        4. Indentation: Prepend 2 spaces per indentation level for nested lists or sub-points (e.g. `  - Sub-item` or `  - [ ] Sub-task`)
        5. Inline formatting:
           - Bold: `**text**`
           - Italic: `*text*`
           - Underline: `<u>text</u>`
           - Strikethrough: `~~text~~`
        
        Guidelines:
        - Automatically identify the context (e.g., shopping list, todo tasks, meeting notes, recipe, study notes).
        - If the content is a cluttered list of items to buy, structure it as a clean checklist: `- [ ] Item`.
        - If it describes a step-by-step process or recipe, format the steps as a numbered list.
        - Use bolding, underlining, or bullets to highlight key headings or topics.
        - Do not use standard Markdown headers like `#` or `##`, code blocks, blockquotes, or hyperlinks.
        
        Output ONLY the organized and formatted note content. Do not include any introduction, conversational replies, quotes, or explanations.
        """
    }
    
    private func organizeNoteWithAI() {
        let trimmedDesc = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedDesc.isEmpty {
            errorMessage = "Can't organize an empty note."
            showErrorAlert = true
            return
        }
        
        isOrganizing = true
        
        Task {
            do {
                let client = OllamaClient()
                let organizedText = try await client.generate(
                    prompt: trimmedDesc,
                    system: aiSystemPrompt
                )
                let cleanedText = organizedText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleanedText.isEmpty {
                    await MainActor.run {
                        text = cleanedText
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
            await MainActor.run {
                isOrganizing = false
            }
        }
    }
    
    private func cancel() {
        reset()
        activeTab = .notes
    }
    
    private func reset() {
        text = ""
        editingNote = nil
    }
}
