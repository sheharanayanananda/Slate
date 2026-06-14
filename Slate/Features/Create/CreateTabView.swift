//
//  CreateTabView.swift
//  Slate
//

import SwiftUI
import SwiftData

struct CreateTabView: View {
    @State private var title: String = ""
    @State private var blocks: [NoteBlock] = [NoteBlock(type: .paragraph, content: "")]
    @State private var focusedBlockId: String? = nil
    
    @Binding var editingNote: SlateModel?
    @Binding var activeTab: ContentView.TabIdentifier

    @Environment(\.modelContext) private var context
    @State private var showEmptyWarning: Bool = false
    @State private var isSummarizing: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert: Bool = false

    private var isDescriptionEmpty: Bool {
        return blocks.allSatisfy { $0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    // Note Title
                    TextField("Title", text: $title)
                        .font(.system(size: 28, weight: .bold))
                        .padding(.horizontal, 4)
                        .padding(.top, 12)
                    
                    Divider()
                        .padding(.horizontal, 4)
                        .padding(.bottom, 8)
                    
                    // Note Blocks
                    ForEach(Array(blocks.enumerated()), id: \.element.id) { index, block in
                        HStack(alignment: .top, spacing: 10) {
                            if block.type == .checklist {
                                Button(action: {
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                    
                                    withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
                                        blocks[index].isChecked.toggle()
                                    }
                                }) {
                                    Image(systemName: block.isChecked ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 21, weight: .medium))
                                        .foregroundColor(block.isChecked ? .blue : .secondary.opacity(0.6))
                                }
                                .buttonStyle(.plain)
                                .padding(.top, 1)
                            }
                            
                            BlockTextField(
                                text: Binding(
                                    get: { blocks[index].content },
                                    set: { blocks[index].content = $0 }
                                ),
                                isFocused: focusedBlockId == block.id,
                                font: blockFont(for: block.type),
                                textColor: blockTextColor(for: block.type),
                                isStrikethrough: block.type == .checklist && block.isChecked,
                                onEnter: {
                                    addBlock(after: block)
                                },
                                onDeleteBackward: {
                                    mergeBlockBackward(at: index)
                                },
                                onFocusChanged: { isFocused in
                                    if isFocused {
                                        focusedBlockId = block.id
                                    } else if focusedBlockId == block.id {
                                        focusedBlockId = nil
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            if let note = editingNote {
                title = note.title
                blocks = NoteBlockParser.parse(desc: note.desc)
            }
        }
        .onChange(of: editingNote) { _, newValue in
            if let note = newValue {
                title = note.title
                blocks = NoteBlockParser.parse(desc: note.desc)
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
            
            // Keyboard Accessory Toolbar
            ToolbarItemGroup(placement: .keyboard) {
                HStack(spacing: 24) {
                    Button(action: toggleChecklist) {
                        Image(systemName: "checklist")
                    }
                    
                    Button(action: makeHeader1) {
                        Image(systemName: "h.square.fill")
                    }
                    
                    Button(action: makeHeader2) {
                        Image(systemName: "h.circle.fill")
                    }
                    
                    Button(action: makeParagraph) {
                        Image(systemName: "paragraph")
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        focusedBlockId = nil
                    }) {
                        Image(systemName: "keyboard.chevron.compact.down")
                    }
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
    
    // MARK: - Helper Methods for Font / Styling
    private func blockFont(for type: NoteBlock.BlockType) -> UIFont {
        switch type {
        case .paragraph, .checklist:
            return UIFont.preferredFont(forTextStyle: .body)
        case .header1:
            return UIFont.systemFont(ofSize: 24, weight: .bold)
        case .header2:
            return UIFont.systemFont(ofSize: 20, weight: .bold)
        }
    }
    
    private func blockTextColor(for type: NoteBlock.BlockType) -> UIColor {
        return UIColor.label
    }
    
    // MARK: - Block Editing Actions
    private func addBlock(after block: NoteBlock) {
        guard let index = blocks.firstIndex(where: { $0.id == block.id }) else { return }
        let newType = block.type == .checklist ? NoteBlock.BlockType.checklist : NoteBlock.BlockType.paragraph
        let newBlock = NoteBlock(type: newType, content: "")
        
        blocks.insert(newBlock, at: index + 1)
        focusedBlockId = newBlock.id
    }
    
    private func mergeBlockBackward(at index: Int) {
        if index == 0 {
            if blocks[0].type == .checklist {
                blocks[0].type = .paragraph
            }
            return
        }
        
        let currentBlock = blocks[index]
        let previousBlock = blocks[index - 1]
        
        blocks[index - 1].content += currentBlock.content
        blocks.remove(at: index)
        focusedBlockId = previousBlock.id
    }
    
    // MARK: - Keyboard Formatting Toolbar Actions
    private func toggleChecklist() {
        guard let focusedId = focusedBlockId,
              let index = blocks.firstIndex(where: { $0.id == focusedId }) else { return }
        
        withAnimation {
            if blocks[index].type == .checklist {
                blocks[index].type = .paragraph
            } else {
                blocks[index].type = .checklist
                blocks[index].isChecked = false
            }
        }
    }
    
    private func makeHeader1() {
        guard let focusedId = focusedBlockId,
              let index = blocks.firstIndex(where: { $0.id == focusedId }) else { return }
        
        withAnimation {
            blocks[index].type = .header1
        }
    }
    
    private func makeHeader2() {
        guard let focusedId = focusedBlockId,
              let index = blocks.firstIndex(where: { $0.id == focusedId }) else { return }
        
        withAnimation {
            blocks[index].type = .header2
        }
    }
    
    private func makeParagraph() {
        guard let focusedId = focusedBlockId,
              let index = blocks.firstIndex(where: { $0.id == focusedId }) else { return }
        
        withAnimation {
            blocks[index].type = .paragraph
        }
    }
    
    // MARK: - Note Lifetime Callbacks
    private func saveNote() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty && isDescriptionEmpty {
            showEmptyWarning = true
            return
        }
        
        let markdown = NoteBlockParser.serializeToMarkdown(blocks: blocks)
        let rtfDesc = MarkdownToRTFConverter.convert(markdown)
        
        if let note = editingNote {
            note.title = trimmedTitle
            note.desc = rtfDesc
            if note.modelContext == nil {
                context.insert(note)
            }
        } else {
            let note = SlateModel(title: trimmedTitle, desc: rtfDesc)
            context.insert(note)
        }
        
        reset()
        activeTab = .notes
    }
    
    private func cancel() {
        reset()
        activeTab = .notes
    }
    
    private func reset() {
        title = ""
        blocks = [NoteBlock(type: .paragraph, content: "")]
        focusedBlockId = nil
        editingNote = nil
    }
    
    private func summarizeNote() {
        let markdown = NoteBlockParser.serializeToMarkdown(blocks: blocks)
        let trimmedDesc = markdown.trimmingCharacters(in: .whitespacesAndNewlines)
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
                
                await MainActor.run {
                    blocks = NoteBlockParser.parse(desc: summary)
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
}
