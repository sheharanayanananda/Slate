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
    @Binding var isLenseProcessing: Bool
    @Binding var lenseStatus: String
    @Binding var lenseResultText: String

    @Environment(\.modelContext) private var context
    @State private var showEmptyWarning: Bool = false
    @State private var isOrganizing: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert: Bool = false
    @State private var wasTitlePreGenerated: Bool = false
    @State private var animationTask: Task<Void, Never>? = nil
    @State private var isAnimatingText: Bool = false
    
    private var typedLinesCount: Int {
        if text.isEmpty { return 0 }
        return text.components(separatedBy: "\n").count
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                if isLenseProcessing || isAnimatingText {
                    SkeletonView(typedLinesCount: typedLinesCount)
                }
                
                NativeTextView(text: $text)
            }
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
        .onChange(of: lenseResultText) { _, newValue in
            if !newValue.isEmpty {
                animateTextLineByLine(newValue)
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
            let trimmedTitle = title
                .replacingOccurrences(of: "\r", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
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
        4. Indentation: Prepend exactly 2 spaces per indentation level for nested sub-points (e.g. `  - Sub-point` or `  - [ ] Sub-task`)
        5. Inline formatting:
           - Bold: `**text**`
           - Italic: `*text*`
           - Underline: `<u>text</u>`
           - Strikethrough: `~~text~~`
        
        ### Strictly Forbidden elements:
        - No Markdown headers like `#` or `##` (use bolding or underlining instead)
        - No Markdown tables (use bullet points or indented lists to organize attributes instead)
        - No Blockquotes (>) or code blocks (```)
        - No HTML tags except `<u>` and `</u>`
        - No Emojis anywhere in the note
        - No Fenced Code Blocks (do NOT wrap your output in triple backticks)
        - No Conversational Preamble or explanations.
        
        ### Intelligence & Context Guidelines:
        - **Shopping/Todo Lists**: If the note contains lists of items to buy, tasks to perform, or actions, structure them as checkbox items: `- [ ] Item`. Do NOT apply bolding (`**`) or any other inline styling to the checkbox items; keep the item text as plain text.
        - **Recipes/Processes**: If the note describes step-by-step instructions or procedures, format them as numbered lists: `1. Step`.
        - **Receipts/Financials**: Organize receipt data into key-value descriptions using bold and underline rather than tables, for example:
          `**Merchant:** Store Name`
          `**Total:** $12.34`
          `  - Item 1: $10.00`
          `  - Taxes: $2.34`
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
                let cleanedText = organizedText
                    .replacingOccurrences(of: "\r", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleanedText.isEmpty {
                    await MainActor.run {
                        animateTextLineByLine(cleanedText)
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
        isLenseProcessing = false
        isAnimatingText = false
        lenseResultText = ""
        animationTask?.cancel()
    }
    
    private func animateTextLineByLine(_ fullText: String) {
        animationTask?.cancel()
        text = ""
        isAnimatingText = true
        
        let lines = fullText.components(separatedBy: "\n")
        
        animationTask = Task { @MainActor in
            for (index, line) in lines.enumerated() {
                guard !Task.isCancelled else { break }
                
                withAnimation(.easeOut(duration: 0.12)) {
                    if index == 0 {
                        text = line
                    } else {
                        text += "\n" + line
                    }
                }
                
                // Play a very subtle tactile feedback on each line to feel responsive
                let generator = UISelectionFeedbackGenerator()
                generator.selectionChanged()
                
                try? await Task.sleep(nanoseconds: 220_000_000) // 220ms per line
            }
            
            isAnimatingText = false
            lenseResultText = ""
        }
    }
}

struct SkeletonLine: View {
    @State private var phase: CGFloat = 0
    @State private var pulse = false
    let width: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.primary.opacity(pulse ? 0.04 : 0.08))
            .frame(width: width, height: 16)
            .overlay(
                GeometryReader { geo in
                    let size = geo.size
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .clear, 
                            Color.primary.opacity(0.12), 
                            Color.primary.opacity(0.04), 
                            .clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: size.width / 1.2)
                    .offset(x: -size.width + (size.width * 2) * phase)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .onAppear {
                withAnimation(Animation.linear(duration: 1.8).repeatForever(autoreverses: false)) {
                    phase = 1.0
                }
                withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }
}

struct SkeletonView: View {
    let typedLinesCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            let widths: [CGFloat] = [140, 300, 260, 280, 120, 240, 270, 180]
            
            ForEach(0..<widths.count, id: \.self) { index in
                if index >= typedLinesCount {
                    SkeletonLine(width: widths[index])
                        .transition(.opacity)
                } else {
                    Color.clear
                        .frame(height: 16)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
}
