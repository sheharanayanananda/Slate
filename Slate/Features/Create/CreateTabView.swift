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
                        
            ToolbarItem(placement: .confirmationAction) {
                HStack(spacing: 16) {
                    if isSummarizing {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Button(action: summarizeNote) {
                            Image(systemName: "text.line.3.summary")
                        }
                        .disabled(desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    
                    Button("Save", systemImage: "checkmark", role: .confirm) {
                        saveNote()
                    }
                    .keyboardShortcut(.defaultAction)
                }
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
        let trimmedDesc = desc.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDesc.isEmpty else { return }
        
        isSummarizing = true
        errorMessage = nil
        
        Task {
            do {
                let client = OllamaClient()
                let summary = try await client.generate(
                    prompt: trimmedDesc,
                    system: "Please summarize the following text in a concise, bulleted manner."
                )
                await MainActor.run {
                    desc = desc + "\n\n**Summary:**\n" + summary
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
