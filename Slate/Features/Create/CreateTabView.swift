//
//  CreateTabView.swift
//  Slate
//
//  Created by Thineth Shehara on 2026-02-08.
//

import SwiftUI
import SwiftData

struct CreateTabView: View {
    @State private var title: String = ""
    @State private var desc: String = ""
    @Binding var editingNote: SlateModel?
    @Binding var activeTab: ContentView.TabIdentifier

    @Environment(\.modelContext) private var context
    @State private var showEmptyWarning: Bool = false
    @State private var isSummarizing: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert: Bool = false

    private var isDescriptionEmpty: Bool {
        var plainText = desc
        if desc.hasPrefix("rtf:"), let data = Data(base64Encoded: String(desc.dropFirst(4))),
           let attr = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil) {
            plainText = attr.string
        }
        return plainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    //----------------- Start of UI Code -----------------//
    var body: some View {
        VStack(spacing: 20) {
            TextField("Title Here", text: $title)
                .font(.title3)
                .padding(.horizontal, 5)
            RichTextEditor(text: $desc)
                .frame(minHeight: 160)
                .overlay(alignment: .topLeading) {
                    if desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Slate it, don't store it.")
                            .foregroundStyle(.secondary)
                            .opacity(0.4)
                            .padding(.horizontal, 5)
                            .padding(.top, 8)
                            .allowsHitTesting(false)
                    }
                }
        }
        .padding()
        .frame(maxHeight: .infinity, alignment: .top)
        .onAppear {
            if let note = editingNote {
                title = note.title
                desc = note.desc
            }
        }
        .onChange(of: editingNote) { _, newValue in
            if let note = newValue {
                title = note.title
                desc = note.desc
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
                    .disabled(isDescriptionEmpty)
                }
            }
                        
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", systemImage: "checkmark", role: .confirm) {
                    saveNote()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .alert("Missing Fields", isPresented: $showEmptyWarning) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Can't save without the title or description. Try again!")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred.")
        }
    }
    //----------------- End of UI Code -----------------//
    
    func saveNote() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDesc = desc.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty && trimmedDesc.isEmpty {
            showEmptyWarning = true
            return
        }
        if let note = editingNote {
            note.title = trimmedTitle
            note.desc = trimmedDesc
            if note.modelContext == nil {
                context.insert(note)
            }
        } else {
            let note = SlateModel(title: trimmedTitle, desc: trimmedDesc)
            context.insert(note)
        }
        
        try? context.save()
        reset()
        activeTab = .notes
    }
    
    func summarizeNote() {
        var plainText = desc
        if desc.hasPrefix("rtf:"), let data = Data(base64Encoded: String(desc.dropFirst(4))),
           let attr = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil) {
            plainText = attr.string
        }
        
        let trimmedDesc = plainText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDesc.isEmpty else { return }
        
        isSummarizing = true
        errorMessage = nil
        
        let noteContent = "Title: \(title)\n\nContent:\n\(trimmedDesc)"
        
        Task {
            do {
                let client = OllamaClient()
                let systemPrompt = """
                You are a precise writing assistant acting directly as the author of this note.
                Your goal is to rewrite the note into a much more summarized, clearly structured, and well-organized version of itself.

                Guidelines:
                1. Role: Write from the same perspective (e.g., using "I" or "we" if present in the original text) and maintain the author's original intent, style, and tone.
                2. Structure: Use clear formatting (such as bullet points, logical headings, or short paragraphs) to make the content highly readable and organized.
                3. Content: Retain all key information, dates, tasks, or critical details while removing fluff, redundancies, and filler words.
                4. Output format: Return ONLY the final revised note content. Do not include any conversational introductions, explanations, wrapping commentary, or concluding sentences (e.g., do NOT say "Here is the summary:").
                """
                let summary = try await client.generate(
                    prompt: noteContent,
                    system: systemPrompt
                )
                let rtfSummary = MarkdownToRTFConverter.convert(summary)
                await MainActor.run {
                    desc = rtfSummary
                    isSummarizing = false
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
    
    func reset() {
        title = ""
        desc = ""
        editingNote = nil
    }

    func cancel() {
        dismissKeyboard()
        reset()
        activeTab = .notes
    }

    func dismissKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}

#Preview {
    ContentView()
}
