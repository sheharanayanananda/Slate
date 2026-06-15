//
//  ContentView.swift
//  Slate
//
//  Created by Thineth Shehara on 2026-02-07.
//

import SwiftUI
import SwiftData
import Vision

struct ContentView: View {

    enum TabIdentifier: Hashable {
        case notes, create, intelligence, settings
    }

    @State private var activeTab: TabIdentifier = .notes
    @State private var editingNote: SlateModel? = nil
    @State private var quickTool: ToolType? = nil
    @State private var showSettings = false

    @State private var isSettingsVisible = false
    @State private var isSettingsInteractable = false
    @State private var settingsViewModel = SettingsViewModel()
    @State private var settingsTransitionTask: Task<Void, Never>? = nil

    // Smart Lens Scanner and Processing States
    @State private var showScanner = false
    @State private var isProcessing = false
    @State private var processStatus = ""
    @State private var processState: ProcessState = .analyzing
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false

    enum ProcessState {
        case analyzing
        case completed
        case failed
    }

    @Environment(\.modelContext) private var context

    private func settingsXOffset(screenWidth: CGFloat) -> CGFloat {
        if showSettings {
            return 0
        } else {
            return -screenWidth
        }
    }

    //----------------- Start of UI Code -----------------//
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            ZStack {
                TabView(selection: $activeTab) {
                    Tab("Slate", systemImage: "scribble.variable", value: .notes) {
                        NavigationStack {
                            SlateTabView(
                                showSettings: $showSettings,
                                onOpenSettings: {
                                    isSettingsVisible = true
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        showSettings = true
                                    }
                                },
                                onCreate: {
                                    editingNote = nil
                                    activeTab = .create
                                },
                                onSelect: { note in
                                    editingNote = note
                                    activeTab = .create
                                },
                                onSmartLens: { showScanner = true },
                                onTranscribe: { quickTool = .transcribe }
                            )
                        }
                    }
                    
                    Tab(editingNote == nil ? "New Note" : "Edit Note", systemImage: "plus", value: .create) {
                        NavigationStack {
                            CreateTabView(editingNote: $editingNote, activeTab: $activeTab)
                        }
                    }
                    
                    Tab("Tools", systemImage: "sparkles", value: .intelligence) {
                        NavigationStack {
                            ToolsTabView(
                                editingNote: $editingNote,
                                activeTab: $activeTab,
                                onSmartLens: { showScanner = true }
                            )
                        }
                    }
                }
                .sheet(item: $quickTool) { tool in
                    ToolSheet(type: tool, editingNote: $editingNote, activeTab: $activeTab)
                }

                // Processing Loader Overlay
                if isProcessing {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        
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
                                .foregroundColor(.primary)
                        }
                        .padding(24)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 30, style: .continuous)
                                    .fill(.clear)
                                    .glassEffect(Glass.clear.tint(.clear), in: .rect(cornerRadius: 30))

                                RoundedRectangle(cornerRadius: 30, style: .continuous)
                                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                            }
                        )
                        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                    }
                    .transition(.opacity)
                    .zIndex(2)
                }

                if isSettingsVisible {
                    NavigationStack {
                        SettingsView(
                            viewModel: settingsViewModel,
                            onDismiss: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    showSettings = false
                                }
                            }
                        )
                        .disabled(!isSettingsInteractable)
                    }
                    .offset(x: settingsXOffset(screenWidth: screenWidth))
                    .zIndex(1)
                }
            }
            .onChange(of: showSettings) { oldValue, newValue in
                settingsTransitionTask?.cancel()
                isSettingsInteractable = false
                
                settingsTransitionTask = Task { @MainActor in
                    if newValue {
                        isSettingsVisible = true
                        
                        // Wait for 0.2s for haptic
                        try? await Task.sleep(nanoseconds: 200_000_000)
                        guard !Task.isCancelled else { return }
                        
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.prepare()
                        generator.impactOccurred()
                        
                        // Wait another 0.15s to enable interactions (total 0.35s)
                        try? await Task.sleep(nanoseconds: 150_000_000)
                        guard !Task.isCancelled else { return }
                        
                        isSettingsInteractable = true
                    } else {
                        // Wait 0.35s for slide-out animation to finish
                        try? await Task.sleep(nanoseconds: 350_000_000)
                        guard !Task.isCancelled else { return }
                        
                        isSettingsVisible = false
                    }
                }
            }
            .fullScreenCover(isPresented: $showScanner) {
                DocumentScannerView(onScanCompleted: { image in
                    showScanner = false
                    if let image = image {
                        processScannedImage(image)
                    }
                }, onCancel: {
                    showScanner = false
                })
                .ignoresSafeArea()
            }
            .alert("AI Feature Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred.")
            }
        }
    }
    
    // Background Processing: Vision Extraction (OCR & Classification) and Ollama API Request
    private func processScannedImage(_ image: UIImage) {
        isProcessing = true
        processState = .analyzing
        processStatus = "Extracting details..."
        
        Task {
            // Run native OCR and classification in parallel on the device
            async let ocrText = performOCR(on: image)
            async let classifications = performClassification(on: image)
            
            let resolvedOcr = await ocrText
            let resolvedClassifications = await classifications
            
            await MainActor.run {
                processStatus = "Analyzing Content"
            }
            
            do {
                let client = OllamaClient()
                
                let systemPrompt = """
                Act as an Intelligent Note-Taking Assistant. You are given a photo scanned by the user, along with on-device Apple Vision text recognition (OCR) and image classification context.
                
                Your goal is to synthesize a highly organized, professional Markdown note based on this combined input.
                
                ### Context from Device:
                - OCR Extracted Text: \(resolvedOcr)
                - Detected Objects/Scenes: \(resolvedClassifications)
                
                ### Rules:
                1. **Title**: Create a concise, meaningful title (maximum 4 words). Do NOT include any emojis in the title.
                2. **No Emojis**: Do NOT use emojis anywhere in the note (neither in the title, headers, checklist, nor body text).
                3. **No Fenced Code Blocks**: Output ONLY the raw Markdown content. Do NOT wrap the entire response in triple backticks or markdown code blocks (e.g. do NOT use ```markdown ... ```).
                4. **Context Synthesis**: Combine the visual cues from the image and the extracted text/classification context. Deduce why the user scanned this (e.g. storing a document, cataloging an object, recording instructions, remembering an item).
                5. **Structured Body**: Format the content cleanly using Markdown headers (`##`, `###`), tables, lists, and bold text. Correct any raw OCR typos.
                6. **Action Items**: Extract a `- [ ]` checklist of explicit or implicit tasks, deadlines, or follow-ups.
                7. **Tone**: Direct and helpful. Output ONLY the raw Markdown note without conversational preamble.
                """
                
                let userPrompt = "Analyze this image and synthesize a clean note."
                let response = try await client.generate(prompt: userPrompt, system: systemPrompt, image: image)
                let parsed = parseResponse(response)
                
                await MainActor.run {
                    processState = .completed
                    processStatus = "Note Created"
                }
                
                try await Task.sleep(nanoseconds: 1_000_000_000)
                
                await MainActor.run {
                    isProcessing = false
                    editingNote = SlateModel(title: parsed.title, desc: parsed.desc)
                    activeTab = .create
                }
            } catch {
                await MainActor.run {
                    processState = .failed
                    processStatus = "Failed to analyze"
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                    isProcessing = false
                }
                print("Failed to process scanned image: \(error)")
            }
        }
    }
    
    private func performOCR(on image: UIImage) async -> String {
        guard let cgImage = image.cgImage else { return "" }
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }
                let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                continuation.resume(returning: text.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(returning: "")
            }
        }
    }
    
    private func performClassification(on image: UIImage) async -> String {
        guard let cgImage = image.cgImage else { return "" }
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        return await withCheckedContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                guard let observations = request.results as? [VNClassificationObservation] else {
                    continuation.resume(returning: "")
                    return
                }
                let classifications = observations
                    .filter { $0.confidence > 0.3 }
                    .prefix(3)
                    .map { "\($0.identifier) (confidence: \(Int($0.confidence * 100))%)" }
                    .joined(separator: ", ")
                continuation.resume(returning: classifications)
            }
            
            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(returning: "")
            }
        }
    }
    
    private func parseResponse(_ response: String) -> (title: String, desc: String) {
        var textToParse = response.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Find content inside ```markdown ... ``` or ``` ... ```
        if let blockRange = textToParse.range(of: "```markdown") {
            let afterBlock = textToParse[blockRange.upperBound...]
            if let endBlockRange = afterBlock.range(of: "```") {
                textToParse = String(afterBlock[..<endBlockRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                textToParse = String(afterBlock).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } else if let blockRange = textToParse.range(of: "```") {
            let afterBlock = textToParse[blockRange.upperBound...]
            if let endBlockRange = afterBlock.range(of: "```") {
                textToParse = String(afterBlock[..<endBlockRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                textToParse = String(afterBlock).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        let lines = textToParse.components(separatedBy: .newlines)
        var title = "New Note"
        var descLines = [String]()
        var foundTitle = false
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                if foundTitle {
                    descLines.append(line)
                }
                continue
            }
            
            // Skip any line starting with triple backticks
            if trimmed.hasPrefix("```") {
                continue
            }
            
            if !foundTitle {
                title = trimmed.replacingOccurrences(of: "#", with: "")
                    .replacingOccurrences(of: "**Title**:", with: "")
                    .trimmingCharacters(in: .whitespaces)
                foundTitle = true
            } else {
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
