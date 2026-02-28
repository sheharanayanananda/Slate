//
//  SmartLenseSheet.swift
//  Slate
//

import SwiftUI

struct SmartLenseSheet: View {
    @Binding var editingNote: SlateModel?
    @Binding var activeTab: ContentView.TabIdentifier
    @Environment(\.dismiss) private var dismiss
    
    @State private var capturedImage: UIImage? = nil
    @State private var takePhoto = false
    @State private var presentationDetent: PresentationDetent = .medium
    @State private var isProcessing: Bool = false
    @State private var processStatus: String = "Analyzing Image"
    
    var body: some View {
        NavigationStack {
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
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.medium, .large], selection: $presentationDetent)
            .overlay {
                if isProcessing {
                    ZStack {
                        Color.black.opacity(0.2).ignoresSafeArea()

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
                        .background(
                            ZStack {
                                // Base glass material
                                RoundedRectangle(cornerRadius: 30, style: .continuous)
                                    .fill(.ultraThinMaterial)

                                // Soft inner glow for depth
                                RoundedRectangle(cornerRadius: 30, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.12),
                                                Color.white.opacity(0.02)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .blendMode(.overlay)

                                // Subtle top highlight to sell the glass effect
                                RoundedRectangle(cornerRadius: 30, style: .continuous)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.35),
                                                Color.white.opacity(0.05)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            }
                        )
                        .shadow(color: Color.black.opacity(0.25), radius: 30, x: 0, y: 12)
                        .padding()
                    }
                    .transition(.opacity)
                }
            }
//            .overlay {
//                if isProcessing {
//                    ZStack {
//                        Color.black.opacity(0.4).ignoresSafeArea()
//                        VStack(spacing: 16) {
//                            if processStatus == "Process Completed" {
//                                Image(systemName: "checkmark.circle.fill")
//                                    .font(.system(size: 40))
//                                    .foregroundColor(.green)
//                            } else {
//                                ProgressView()
//                                    .controlSize(.large)
//                            }
//                            Text(processStatus)
//                                .font(.headline)
//                        }
//                        .padding(24)
//                        .background {
//                            RoundedRectangle(cornerRadius: 40, style: .continuous)
//                                .fill(.clear)
//                                .glassEffect(Glass.clear.tint(.clear), in: .rect(cornerRadius: 30))
//                        }
//                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
//                    }
//                }
//            }
        }
    }
    
    func createAINote(with image: UIImage) {
        isProcessing = true
        processStatus = "Analyzing Image"
        
        Task {
            do {
                let client = OllamaClient()
                let prompt = """
                Act as an intelligent, highly observant Note-Taking Assistant. Deeply analyze the provided image and generate a highly accurate, structured Markdown note that captures both the literal content and the underlying context. You are encouraged to use relevant emojis throughout the note to make it engaging and visually scannable.

                ### STRATEGY:
                1. **For text-heavy images (documents, receipts, whiteboards):** Extract the most critical information, group related concepts logically, and provide a clear, synthesized summary rather than a raw transcription. Highlight key figures, dates, or concepts.
                2. **For objects or scenes (plants, gadgets, landmarks, environments):** Accurately identify the main subjects, describe their key characteristics, and infer the user's intent to provide intelligent contextual suggestions (e.g., detailed care instructions, technical specifications, or historical context).
                3. **For abstract or complex diagrams:** Break down the core components, explain the relationships, and summarize the overall purpose.

                ### OUTPUT STRUCTURE:
                - **Title**: A concise, descriptive, and punchy title for the note (maximum 3 words, include a relevant emoji).
                - **Note Type**: Categorize the content (e.g., 📄 Document, 🧾 Receipt, 🌿 Nature, 💻 Tech, 💡 Idea).
                - **Summary**: A smart, 1-2 sentence overview synthesizing the image's core value or main takeaway.
                - **Key Details**: Use organized bullet points to present extracted text, specifications, amounts, or defining physical traits clearly.
                - **Actionable Insights**: 2-3 highly relevant, logical next steps based on the context (e.g., '📅 Schedule follow-up meeting,' '💧 Water every 3 days,' '🔎 Research compatibility').
                - **Tags**: 3-5 relevant, searchable hashtags.

                ### STYLE GUIDELINES:
                - Be concise, professional, and intelligent.
                - Integrate emojis naturally to enhance readability.
                - Never use phrasing like 'In this image,' 'I can see,' or 'The image shows.' Present the information directly and confidently as if the user authored it.
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
        
        let desc = descLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return (title, desc)
    }
}

#Preview {
    ContentView()
}
