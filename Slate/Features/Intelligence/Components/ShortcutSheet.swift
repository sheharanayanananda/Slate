//
//  ShortcutSheet.swift
//  Slate
//

import SwiftUI

enum ShortcutType: Identifiable {
    case imageToNote
    case transcript
    case summerize
    
    var id: Self { self }
}

struct ShortcutSheet: View {
    let type: ShortcutType
    @Binding var editingNote: SlateModel?
    @Binding var activeTab: ContentView.TabIdentifier
    @Environment(\.dismiss) private var dismiss
    
    @State private var capturedImage: UIImage? = nil
    @State private var takePhoto = false
    @State private var presentationDetent: PresentationDetent = .medium
    @State private var isProcessing: Bool = false
    @State private var processStatus: String = "Analyzing Image..."
    
    var body: some View {
        NavigationStack {
            Group {
                switch type {
                case .imageToNote:
                    ZStack {
                        if let image = capturedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipped()
                                .ignoresSafeArea()
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarLeading) {
                                        Button(role: .cancel, action: {
                                            capturedImage = nil
                                            presentationDetent = .medium
                                        })
//                                        Button("Retake") {
//                                            capturedImage = nil
//                                            presentationDetent = .medium
//                                        }
                                    }
                                    ToolbarItem(placement: .navigationBarTrailing) {
                                        Button("Process") {
                                            if let image = capturedImage {
                                                createAINote(with: image)
                                            }
                                        }
                                        .disabled(isProcessing)
                                        .buttonStyle(.glassProminent)
                                        .tint(.accentColor)
                                    }
                                }
                                .toolbarBackground(.hidden, for: .navigationBar)
                        } else {
                            CameraView(takePhoto: $takePhoto) { image in
                                if let image = image {
                                    capturedImage = image
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .ignoresSafeArea()
                            
                            VStack {
                                Spacer()
                                Button(action: {
                                    takePhoto = true
                                }) {
                                    Circle()
                                        .fill(Color.white.opacity(0.5))
                                        .frame(width: 80, height: 80)
                                        .shadow(radius: 5)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: 5)
                                        )
                                }
                                .padding(.bottom, 30)
                            }
                            .toolbar(.hidden, for: .navigationBar)
                        }
                    }
                case .transcript:
                    VStack(spacing: 16) {
                        Text("Transcript")
                            .font(.title2)
                            .bold()
                        Text("Coming Soon…")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                case .summerize:
                    VStack(spacing: 16) {
                        Text("Summerize")
                            .font(.title2)
                            .bold()
                        Text("Coming Soon…")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.medium, .large], selection: $presentationDetent)
            .overlay {
                if isProcessing {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        VStack(spacing: 16) {
                            if processStatus == "Process Completed" {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.green)
                            } else {
                                ProgressView()
                                    .controlSize(.large)
                            }
                            Text(processStatus)
                                .font(.headline)
                        }
                        .padding(24)
                        .background {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(uiColor: .systemBackground))
                        }
                        .shadow(radius: 10)
                    }
                }
            }
        }
    }
    
    func createAINote(with image: UIImage) {
        isProcessing = true
        processStatus = "Analyzing Image..."
        
        Task {
            do {
                let client = OllamaClient()
                let prompt = """
                Act as an intelligent Note-Taking Assistant. Analyze the provided image and generate a structured Markdown note based on what you see.

                ### STRATEGY:
                1. **If the image is text-heavy (document, receipt, whiteboard):** Extract the key information and organize it logically. Do not just transcribe; summarize.
                2. **If the image is an object (flower, device, landmark):** Identify the item, provide a brief description, and suggest why the user might be saving it (e.g., care instructions for a plant, specs for a gadget).

                ### OUTPUT STRUCTURE:
                - **Title**: A short, punchy title for the note.
                - **Note Type**: (e.g., Document, Receipt, Nature, Tech, Reminder).
                - **Summary**: A 1-2 sentence overview of the image contents.
                - **Detailed Info**: Use bullet points for extracted text, dates, prices, or physical characteristics.
                - **Action Items**: 2-3 logical next steps (e.g., 'Add to expense report,' 'Water twice a week,' or 'Research this model').
                - **Tags**: 3-5 relevant hashtags.

                ### STYLE GUIDELINE:
                Be concise and professional. Do not say 'In this image' or 'I see.' Simply present the note as if the user wrote it themselves.
                """
                let response = try await client.generate(prompt: prompt, image: image)
                let parsed = parseResponse(response)
                
                await MainActor.run {
                    processStatus = "Process Completed"
                }
                
                try await Task.sleep(nanoseconds: 1_000_000_000)
                
                await MainActor.run {
                    isProcessing = false
                    editingNote = SlateModel(title: parsed.title, desc: parsed.desc)
                    activeTab = .create
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    processStatus = "Failed to analyze"
                }
                try await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    isProcessing = false
                }
                print("Failed to generate AI note: \\(error)")
            }
        }
    }
    
    func parseResponse(_ response: String) -> (title: String, desc: String) {
        let lines = response.components(separatedBy: .newlines)
        var title = "New Note"
        var descLines = [String]()
        var foundTitle = false
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !foundTitle && (trimmed.hasPrefix("# ") || trimmed.hasPrefix("## ") || trimmed.hasPrefix("### ") || trimmed.hasPrefix("**Title**: ")) {
                title = trimmed.replacingOccurrences(of: "#", with: "")
                    .replacingOccurrences(of: "**Title**:", with: "")
                    .trimmingCharacters(in: .whitespaces)
                foundTitle = true
            } else if !foundTitle && !trimmed.isEmpty {
                title = trimmed
                foundTitle = true
            } else if foundTitle {
                descLines.append(line)
            }
        }
        
        let desc = descLines.joined(separator: "\\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return (title, desc)
    }
}

#Preview {
    ContentView()
}
