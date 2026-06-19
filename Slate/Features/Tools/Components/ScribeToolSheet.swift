//
//  ScribeToolSheet.swift
//  Slate
//

import SwiftUI
import SwiftData

struct ScribeToolSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    enum ScribeState {
        case idle
        case recording
        case processing
        case completed
    }
    
    @State private var currentState: ScribeState = .idle
    @State private var recordingSeconds = 0
    @State private var timer: Timer?
    @State private var dictationText = ""
    @State private var waveformHeights: [CGFloat] = Array(repeating: 10, count: 15)
    @State private var waveformTimer: Timer?
    
    // Hardcoded simulation timeline
    private let dictationSteps = [
        "Hey Slate...",
        "Hey Slate, create a checklist for my launch plan tomorrow...",
        "Hey Slate, create a checklist for my launch plan tomorrow and review the design notes.",
    ]
    
    private let mockTitle = "Launch Plan Checklist"
    private let mockDesc = "Launch Plan\n\n**Action Items**\n- [ ] Complete launch plan tasks\n- [ ] Review design notes"
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                switch currentState {
                case .idle:
                    idleView
                case .recording:
                    recordingView
                case .processing:
                    processingView
                case .completed:
                    completedView
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Scribe")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.medium, .large])
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        stopAllSimulations()
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
            .onDisappear {
                stopAllSimulations()
            }
        }
    }
    
    private var idleView: some View {
        VStack(spacing: 24) {
            Button(action: startRecordingSimulation) {
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.12))
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .fill(Color.purple.opacity(0.2))
                        .frame(width: 96, height: 96)
                    
                    Image(systemName: "mic.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.purple)
                }
            }
            
            VStack(spacing: 8) {
                Text("Scribe Voice Agent")
                    .font(.title2)
                    .bold()
                
                Text("Tap the microphone to dictate your thoughts. Scribe will transcribe your speech and use Gemma AI to structure it into formatted notes.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            Divider()
                .padding(.horizontal, 40)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .foregroundColor(.purple)
                        .frame(width: 24)
                    VStack(alignment: .leading) {
                        Text("Vocal Dictation")
                            .font(.subheadline)
                            .bold()
                        Text("Speak naturally to dictate tasks, checklists, or summaries.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 16) {
                    Image(systemName: "waveform.and.mic")
                        .foregroundColor(.purple)
                        .frame(width: 24)
                    VStack(alignment: .leading) {
                        Text("On-Device Speech Recognition")
                            .font(.subheadline)
                            .bold()
                        Text("Audio processed securely on-device with Speech framework.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)
                        .frame(width: 24)
                    VStack(alignment: .leading) {
                        Text("Intelligence Structuring")
                            .font(.subheadline)
                            .bold()
                        Text("Gemma model extracts tasks, timelines, and builds slates.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var recordingView: some View {
        VStack(spacing: 32) {
            Text(timeString(from: recordingSeconds))
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(.purple)
            
            HStack(spacing: 4) {
                ForEach(0..<15) { index in
                    Capsule()
                        .fill(Color.purple)
                        .frame(width: 6, height: waveformHeights[index])
                        .animation(.easeInOut(duration: 0.15), value: waveformHeights[index])
                }
            }
            .frame(height: 80)
            
            VStack(spacing: 12) {
                Text("Listening...")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("\"\(dictationText)\"")
                    .font(.body)
                    .italic()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .frame(height: 60)
            }
            
            Button(action: stopRecordingSimulation) {
                HStack(spacing: 8) {
                    Image(systemName: "stop.fill")
                    Text("Stop & Process")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.red)
                .cornerRadius(24)
            }
        }
    }
    
    private var processingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .controlSize(.large)
                .tint(.purple)
            
            VStack(spacing: 8) {
                Text("Analyzing Speech")
                    .font(.headline)
                Text("Gemma is structuring your note details...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var completedView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            VStack(spacing: 8) {
                Text("Note Structured")
                    .font(.title2)
                    .bold()
                Text("A new note has been successfully compiled from your dictation.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text(mockTitle)
                    .font(.headline)
                    .padding(.bottom, 4)
                
                Text(mockDesc)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal, 24)
            
            Button(action: saveMockNote) {
                Text("Add to Slates")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
            }
        }
    }
    
    private func startRecordingSimulation() {
        currentState = .recording
        recordingSeconds = 0
        dictationText = dictationSteps[0]
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            recordingSeconds += 1
            if recordingSeconds < dictationSteps.count {
                dictationText = dictationSteps[recordingSeconds]
            } else if recordingSeconds >= 6 {
                stopRecordingSimulation()
            }
        }
        
        waveformTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            for i in 0..<15 {
                waveformHeights[i] = CGFloat.random(in: 10...70)
            }
        }
    }
    
    private func stopRecordingSimulation() {
        timer?.invalidate()
        timer = nil
        waveformTimer?.invalidate()
        waveformTimer = nil
        
        guard currentState == .recording else { return }
        
        currentState = .processing
        
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                currentState = .completed
            }
        }
    }
    
    private func stopAllSimulations() {
        timer?.invalidate()
        timer = nil
        waveformTimer?.invalidate()
        waveformTimer = nil
    }
    
    private func saveMockNote() {
        let note = SlateModel(title: mockTitle, desc: mockDesc)
        context.insert(note)
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        dismiss()
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

#Preview {
    ScribeToolSheet()
}
