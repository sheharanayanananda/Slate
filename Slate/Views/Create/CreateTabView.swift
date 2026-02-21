//
//  CreateTabView.swift
//  Slate
//
//  Created by Thineth Shehara on 2026-02-08.
//

import SwiftUI
import SwiftData
import Vision

struct CreateTabView: View {
    @State private var title: String = ""
    @State private var desc: String = ""
    @Binding var editingNote: SlateModel?
    @Binding var activeTab: ContentView.TabIdentifier

    @Environment(\.modelContext) private var context
    @State private var showEmptyWarning: Bool = false
    @State private var showCamera: Bool = false
    @State private var recognizedImage: UIImage?

    //----------------- Start of UI Code -----------------//
    var body: some View {
        VStack(spacing: 20) {
            TextField("Title Here", text: $title)
                .font(.title3)
                .padding(.horizontal, 5)
            TextEditor(text: $desc)
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
        .sheet(isPresented: $showCamera, onDismiss: {
            if let image = recognizedImage {
                recognizeText(from: image)
            }
        }) {
            ImagePicker(image: $recognizedImage)
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
                Button("AI Lense", systemImage: "document.viewfinder") {
                    showCamera = true
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
        } else {
            let note = SlateModel(title: trimmedTitle, desc: trimmedDesc)
            context.insert(note)
        }
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
    
    func recognizeText(from image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                return
            }
            
            let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
            
            DispatchQueue.main.async {
                self.desc = text
                
                let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
                if words.count >= 3 {
                    self.title = words.prefix(3).joined(separator: " ")
                } else {
                    self.title = text
                }
            }
        }
        
        request.recognitionLevel = .accurate
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }
}

#Preview {
    ContentView()
}
