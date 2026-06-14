//
//  TranscribeToolSheet.swift
//  Slate
//

import SwiftUI

struct TranscribeToolSheet: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "waveform")
                    .font(.system(size: 60))
                    .foregroundColor(.pink)
                    .padding(24)
                    .background(Color.pink.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(spacing: 8) {
                    Text("Audio Transcribe")
                        .font(.title2)
                        .bold()
                    
                    Text("Record voice memos or import audio files to automatically generate beautifully formatted, structured notes in real-time.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Text("Coming Soon")
                    .font(.caption)
                    .bold()
                    .foregroundStyle(.pink)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.pink.opacity(0.12))
                    .clipShape(Capsule())
                
                Spacer()
            }
            .padding()
            .navigationTitle("Transcribe")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.medium, .large])
        }
    }
}

#Preview {
    ContentView()
}
