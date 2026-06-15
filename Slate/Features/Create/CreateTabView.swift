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
    @State private var selectedTextRange: NSRange? = nil
    @State private var showFormattingSheet: Bool = false
    
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
                        .font(.system(size: 20, weight: .semibold))
                        .padding(.horizontal, 4)
                        .padding(.top, 12)
                    
                    Divider()
                        .padding(.horizontal, 4)
                        .padding(.bottom, 8)
                    
                    // Note Blocks
                    ForEach(Array(blocks.enumerated()), id: \.element.id) { index, block in
                        HStack(alignment: .top, spacing: 10) {
                            // Indentation Padding
                            if block.indent > 0 {
                                Spacer()
                                    .frame(width: CGFloat(block.indent * 20))
                            }
                            
                            // Left-side Block Type Indicator (Checklist circle, Bullet dot, Number)
                            if block.type == .checklist {
                                Button(action: {
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                    
                                    withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
                                        blocks[index].isChecked.toggle()
                                    }
                                }) {
                                    Image(systemName: block.isChecked ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(block.isChecked ? .blue : .secondary.opacity(0.6))
                                }
                                .buttonStyle(.plain)
                                .frame(height: firstLineHeight(for: block.type), alignment: .center)
                            } else if block.type == .bullet {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .frame(height: firstLineHeight(for: block.type), alignment: .center)
                            } else if block.type == .numbered {
                                let itemNumber = calculateNumberedIndex(at: index)
                                Text("\(itemNumber).")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.secondary)
                                    .frame(width: 20, alignment: .trailing)
                                    .frame(height: firstLineHeight(for: block.type), alignment: .center)
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
                                selectedRange: Binding(
                                    get: { focusedBlockId == block.id ? selectedTextRange : nil },
                                    set: { if focusedBlockId == block.id { selectedTextRange = $0 } }
                                ),
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
                                },
                                onToggleFormat: {
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                    focusedBlockId = nil
                                    showFormattingSheet = true
                                },
                                onToggleChecklist: {
                                    toggleBlockType(to: .checklist)
                                },
                                onToggleBullet: {
                                    toggleBlockType(to: .bullet)
                                },
                                onToggleNumbered: {
                                    toggleBlockType(to: .numbered)
                                },
                                onDecreaseIndent: {
                                    changeIndent(by: -1)
                                },
                                onIncreaseIndent: {
                                    changeIndent(by: 1)
                                },
                                onDismissKeyboard: {
                                    focusedBlockId = nil
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
            } else {
                title = ""
                blocks = [NoteBlock(type: .paragraph, content: "")]
                focusedBlockId = nil
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
        .sheet(isPresented: $showFormattingSheet) {
            FormattingSheet(
                blocks: $blocks,
                focusedBlockId: focusedBlockId,
                selectedTextRange: $selectedTextRange
            )
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled(upThrough: .height(280)))
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
        case .paragraph, .checklist, .bullet, .numbered:
            return UIFont.preferredFont(forTextStyle: .body)
        case .header1:
            return UIFont.systemFont(ofSize: 24, weight: .bold)
        case .header2:
            return UIFont.systemFont(ofSize: 20, weight: .bold)
        case .subheading:
            return UIFont.systemFont(ofSize: 18, weight: .semibold)
        }
    }
    
    private func blockTextColor(for type: NoteBlock.BlockType) -> UIColor {
        return UIColor.label
    }
    
    private func firstLineHeight(for type: NoteBlock.BlockType) -> CGFloat {
        return blockFont(for: type).lineHeight
    }
    
    // MARK: - Block Editing Actions
    private func addBlock(after block: NoteBlock) {
        guard let index = blocks.firstIndex(where: { $0.id == block.id }) else { return }
        
        if block.content.isEmpty {
            if block.indent > 0 {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.85)) {
                    blocks[index].indent -= 1
                }
                return
            } else if block.type != .paragraph {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.85)) {
                    blocks[index].type = .paragraph
                }
                return
            }
        }
        
        let newType: NoteBlock.BlockType
        switch block.type {
        case .checklist:
            newType = .checklist
        case .bullet:
            newType = .bullet
        case .numbered:
            newType = .numbered
        default:
            newType = .paragraph
        }
        
        let newBlock = NoteBlock(type: newType, content: "", isChecked: false, indent: block.indent)
        
        withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
            blocks.insert(newBlock, at: index + 1)
        }
        focusedBlockId = newBlock.id
    }
    
    private func mergeBlockBackward(at index: Int) {
        let currentBlock = blocks[index]
        
        if currentBlock.indent > 0 {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.85)) {
                blocks[index].indent -= 1
            }
            return
        }
        
        if currentBlock.type != .paragraph && currentBlock.content.isEmpty {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.85)) {
                blocks[index].type = .paragraph
            }
            return
        }
        
        if index == 0 {
            return
        }
        
        let previousBlock = blocks[index - 1]
        
        withAnimation(.spring(response: 0.2, dampingFraction: 0.85)) {
            blocks[index - 1].content += currentBlock.content
            blocks.remove(at: index)
        }
        focusedBlockId = previousBlock.id
    }
    
    private func calculateNumberedIndex(at index: Int) -> Int {
        let block = blocks[index]
        guard block.type == .numbered else { return 1 }
        
        var count = 1
        var idx = index - 1
        while idx >= 0 {
            let prev = blocks[idx]
            if prev.indent == block.indent {
                if prev.type == .numbered {
                    count += 1
                } else if prev.type != .paragraph || !prev.content.isEmpty {
                    break
                }
            } else if prev.indent < block.indent {
                break
            }
            idx -= 1
        }
        return count
    }
    
    // MARK: - Keyboard Formatting Actions
    private func toggleBlockType(to type: NoteBlock.BlockType) {
        guard let id = focusedBlockId,
              let index = blocks.firstIndex(where: { $0.id == id }) else { return }
        
        withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
            if blocks[index].type == type {
                blocks[index].type = .paragraph
            } else {
                blocks[index].type = type
                if type == .checklist {
                    blocks[index].isChecked = false
                }
            }
        }
    }
    
    private func changeIndent(by delta: Int) {
        guard let id = focusedBlockId,
              let index = blocks.firstIndex(where: { $0.id == id }) else { return }
        
        withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
            let current = blocks[index].indent
            blocks[index].indent = max(0, min(5, current + delta))
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
        
        if let note = editingNote {
            note.title = trimmedTitle
            note.desc = markdown
            if note.modelContext == nil {
                context.insert(note)
            }
        } else {
            let note = SlateModel(title: trimmedTitle, desc: markdown)
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

struct FormattingSheet: View {
    @Binding var blocks: [NoteBlock]
    var focusedBlockId: String?
    @Binding var selectedTextRange: NSRange?
    
    @Environment(\.dismiss) private var dismiss
    
    private var activeBlockIndex: Int? {
        guard let id = focusedBlockId else { return nil }
        return blocks.firstIndex(where: { $0.id == id })
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Format")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.top, 12)
            
            // 1. Text Style Selection (Title, Heading, Subheading, Body)
            HStack(spacing: 8) {
                styleButton(title: "Title", type: .header1)
                styleButton(title: "Heading", type: .header2)
                styleButton(title: "Subheading", type: .subheading)
                styleButton(title: "Body", type: .paragraph)
            }
            .padding(.horizontal, 16)
            
            // 2. Inline styles (Bold, Italic, Strikethrough) & Indentation
            HStack(spacing: 12) {
                HStack(spacing: 2) {
                    inlineStyleButton(systemImage: "bold", wrapper: "**")
                    inlineStyleButton(systemImage: "italic", wrapper: "*")
                    inlineStyleButton(systemImage: "strikethrough", wrapper: "~~")
                }
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                Spacer()
                
                HStack(spacing: 2) {
                    indentButton(systemImage: "decrease.indent", delta: -1)
                    indentButton(systemImage: "increase.indent", delta: 1)
                }
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .padding(.horizontal, 16)
            
            // 3. Block Lists
            HStack(spacing: 10) {
                listTypeButton(title: "Checklist", systemImage: "checklist", type: .checklist)
                listTypeButton(title: "Bulleted", systemImage: "list.bullet", type: .bullet)
                listTypeButton(title: "Numbered", systemImage: "list.number", type: .numbered)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color(.systemBackground))
    }
    
    private func styleButton(title: String, type: NoteBlock.BlockType) -> some View {
        let isActive = activeBlockIndex != nil && blocks[activeBlockIndex!].type == type
        
        return Button(action: {
            guard let idx = activeBlockIndex else { return }
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(.spring(response: 0.2, dampingFraction: 0.85)) {
                blocks[idx].type = type
            }
        }) {
            Text(title)
                .font(.system(size: 14, weight: isActive ? .bold : .medium))
                .foregroundColor(isActive ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isActive ? Color.blue : Color(.systemGray6))
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
    
    private func inlineStyleButton(systemImage: String, wrapper: String) -> some View {
        Button(action: {
            guard let idx = activeBlockIndex else { return }
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            let content = blocks[idx].content
            let nsString = content as NSString
            let range = selectedTextRange ?? NSRange(location: nsString.length, length: 0)
            let selectedText = nsString.substring(with: range)
            
            let newSubstring: String
            let isWrappingEmpty = selectedText.isEmpty
            
            if selectedText.hasPrefix(wrapper) && selectedText.hasSuffix(wrapper) {
                newSubstring = String(selectedText.dropFirst(wrapper.count).dropLast(wrapper.count))
            } else {
                newSubstring = wrapper + selectedText + wrapper
            }
            
            let newContent = nsString.replacingCharacters(in: range, with: newSubstring)
            blocks[idx].content = newContent
            
            if isWrappingEmpty {
                selectedTextRange = NSRange(location: range.location + wrapper.count, length: 0)
            } else {
                selectedTextRange = NSRange(location: range.location, length: newSubstring.count)
            }
        }) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 44, height: 38)
        }
        .buttonStyle(.plain)
    }
    
    private func indentButton(systemImage: String, delta: Int) -> some View {
        Button(action: {
            guard let idx = activeBlockIndex else { return }
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
                let current = blocks[idx].indent
                blocks[idx].indent = max(0, min(5, current + delta))
            }
        }) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 44, height: 38)
        }
        .buttonStyle(.plain)
    }
    
    private func listTypeButton(title: String, systemImage: String, type: NoteBlock.BlockType) -> some View {
        let isActive = activeBlockIndex != nil && blocks[activeBlockIndex!].type == type
        
        return Button(action: {
            guard let idx = activeBlockIndex else { return }
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
                if blocks[idx].type == type {
                    blocks[idx].type = .paragraph
                } else {
                    blocks[idx].type = type
                    if type == .checklist {
                        blocks[idx].isChecked = false
                    }
                }
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .medium))
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(isActive ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isActive ? Color.blue : Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

