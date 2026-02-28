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
    
    func reset() {
        title = ""
        desc = ""
        editingNote = nil
    }

    func cancel() {
        dismissKeyboard()
        
        if editingNote != nil {
            // Navigate back when editing an existing note
            activeTab = .notes
            reset()
        } else {
            let hasContent = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                             !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            
            if hasContent {
                // If content is typed for a new note, "Cancel" acts as a "Clear" action
                reset()
            } else {
                // If it is already empty, navigate back
                activeTab = .notes
            }
        }
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
