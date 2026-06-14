//
//  SmartLensSheet.swift
//  Slate
//

import SwiftUI

struct SmartLensSheet: View {
    @Binding var editingNote: SlateModel?
    @Binding var activeTab: ContentView.TabIdentifier
    @Environment(\.dismiss) private var dismiss
    
    @State private var capturedImage: UIImage? = nil
    @State private var takePhoto = false
    @State private var presentationDetent: PresentationDetent = .medium
    @State private var isProcessing: Bool = false
    @State private var processState: ProcessState = .analyzing
    @State private var processStatus: String = "Analyzing Image"
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert: Bool = false
    
    enum ProcessState {
        case analyzing
        case completed
        case failed
    }
    
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
                                }) {
                                    Text("Retake")
                                }
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
                                .fill(.clear)
                                .glassEffect(Glass.clear.tint(.clear), in: .rect(cornerRadius: 100))
                                .frame(width: 80, height: 80)
                                .shadow(radius: 5)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 7)
                                        .opacity(0.4)
                                )
                        }
                        .padding(.bottom, 30)
                    }
                    .toolbar(.hidden, for: .navigationBar)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.medium, .large], selection: $presentationDetent)
            .alert("AI Feature Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred.")
            }
            .overlay {
                if isProcessing {
                    ZStack {
                        Color.black.opacity(0.2).ignoresSafeArea()

                        VStack(spacing: 16) {
                            if processState == .completed {
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
                                RoundedRectangle(cornerRadius: 30, style: .continuous)
                                    .fill(.clear)
                                    .glassEffect(Glass.clear.tint(.clear), in: .rect(cornerRadius: 30))

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
        }
    }
    
    func createAINote(with image: UIImage) {
        isProcessing = true
        processState = .analyzing
        processStatus = "Analyzing Image"
        
        Task {
            do {
                let client = OllamaClient()
                let systemPrompt = """
                Act as an intelligent, highly observant, and proactive Note-Taking Assistant. Your primary goal is to analyze the provided image to deduce the *context and purpose* behind why the user took it, rather than just describing its literal contents.
                
                Think critically about the situation. For example:
                - If it's a photo of an almost empty package (e.g., 2 cheese wedges left in an 8-pack), deduce that the user needs a reminder to buy more.
                - If it's a photo of a broken device (e.g., a phone with a cracked screen), deduce that the user needs a reminder to get it repaired.
                - If it's a document/receipt, deduce that the user wants to securely store its critical data (amounts, dates, key figures).
                
                Analyze the image, determine the user's implicit intent, and generate a highly accurate, structured Markdown note. Use relevant emojis naturally to make it engaging and visually scannable.

                ### OUTPUT STRUCTURE:
                - **Title**: A concise, descriptive title capturing the *intent* (maximum 3-4 words, include a relevant emoji).
                - **Note Type**: Categorize the content (e.g., 🛒 Shopping Reminder, 🔧 Repair Update, 📄 Document, 💡 Idea).
                - **Summary**: A smart, 1-2 sentence overview synthesizing the situation and what it implies for the user.
                - **Key Details**: Use bullet points to highlight the critical observations (e.g., "Only 2 wedges left out of 8", "Screen is heavily cracked at the bottom").
                - **Actionable Insights**: 2-3 highly relevant, logical next steps based on your deduction of the situation (e.g., '🛒 Add cheese to grocery list for next trip,' '📅 Schedule repair appointment at Apple Store').
                - **Tags**: 3-5 relevant, searchable hashtags.

                ### STYLE GUIDELINES:
                - Be concise, direct, and actionable.
                - Never use phrasing like 'In this image,' 'I can see,' or 'The image shows.' Write as if the user is writing a helpful note to themselves.
                """
                let userPrompt = "Analyze this image and create a contextually aware note based on the situation."
                let response = try await client.generate(prompt: userPrompt, system: systemPrompt, image: image)
                let parsed = parseResponse(response)
                
                await MainActor.run {
                    processState = .completed
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
                    processState = .failed
                    processStatus = "Failed to analyze"
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                    isProcessing = false // Reset immediately on error so UI is not frozen
                }
                print("Failed to generate AI note: \(error)")
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
