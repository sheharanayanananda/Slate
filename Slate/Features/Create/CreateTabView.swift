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

    var body: some View {
        VStack(spacing: 0) {
            NativeTextView(text: $text)
        }
        .onAppear {
            if let note = editingNote {
                text = note.desc
            }
        }
        .onChange(of: editingNote) { _, newValue in
            if let note = newValue {
                text = note.desc
            } else {
                text = ""
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
        
        Task {
            await generateTitleInBackground(for: targetNote, content: trimmedDesc)
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
    
    private func cancel() {
        reset()
        activeTab = .notes
    }
    
    private func reset() {
        text = ""
        editingNote = nil
    }
}
