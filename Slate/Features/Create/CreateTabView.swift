//
//  CreateTabView.swift
//  Slate
//

import SwiftUI
import SwiftData

struct CreateTabView: View {
    @State private var text: String = ""
    @State private var rtfData: Data? = nil
    
    @Binding var editingNote: SlateModel?
    @Binding var activeTab: ContentView.TabIdentifier

    @Environment(\.modelContext) private var context
    @State private var showEmptyWarning: Bool = false
    @State private var isSummarizing: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            NativeTextView(text: $text, rtfData: $rtfData)
        }
        .onAppear {
            if let note = editingNote {
                text = note.desc
                rtfData = note.rtfData
            }
        }
        .onChange(of: editingNote) { _, newValue in
            if let note = newValue {
                text = note.desc
                rtfData = note.rtfData
            } else {
                text = ""
                rtfData = nil
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
            
            ToolbarItem(placement: .topBarTrailing) {
                if isSummarizing {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button(action: summarizeNote) {
                        Image(systemName: "text.line.3.summary")
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
        .alert("Error", isPresented: $showErrorAlert) {
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
            note.rtfData = rtfData
            if note.title.isEmpty {
                note.title = initialTitle
            }
            targetNote = note
            if targetNote.modelContext == nil {
                context.insert(targetNote)
            }
        } else {
            targetNote = SlateModel(title: initialTitle, desc: trimmedDesc, rtfData: rtfData)
            context.insert(targetNote)
        }
        
        Task {
            await generateTitleInBackground(for: targetNote, content: trimmedDesc)
        }
        
        reset()
        activeTab = .notes
    }
    
    private func summarizeNote() {
        let trimmedDesc = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDesc.isEmpty else { return }
        
        isSummarizing = true
        errorMessage = nil
        
        let noteContent = "Content to summarize:\n\(trimmedDesc)"
        
        Task {
            do {
                let client = OllamaClient()
                let systemPrompt = """
                You are a context-aware note summarization assistant. Analyze the user's raw note text and determine its intent (e.g., meeting notes, shopping list, journal entry, instructions). 
                
                Your goal is to restructure and rewrite the note into a much cleaner, organized, and properly formatted version using Markdown.
                
                Rules:
                1. If it looks like a list of things to buy or do, format it STRICTLY as a Markdown checklist using `- [ ] item`.
                2. If it's a meeting or lecture, use logical headings (`##`, `###`) and bullet points.
                3. Retain all key information but remove fluff.
                4. Output ONLY the raw Markdown text. Do NOT wrap it in triple backticks or markdown code blocks (e.g. do NOT use ```markdown ... ```). Do NOT include conversational filler like "Here is your summary".
                """
                let summary = try await client.generate(
                    prompt: noteContent,
                    system: systemPrompt
                )
                
                await MainActor.run {
                    // Actually, setting `text = summary` and `rtfData = nil` is the safest way to force `NativeTextView` to load the plain text.
                    self.rtfData = nil
                    self.text = summary
                    
                    self.isSummarizing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                    isSummarizing = false
                }
            }
        }
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
    
    private func cancel() {
        reset()
        activeTab = .notes
    }
    
    private func reset() {
        text = ""
        rtfData = nil
        editingNote = nil
    }
}
