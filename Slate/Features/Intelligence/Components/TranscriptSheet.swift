//
//  TranscriptSheet.swift
//  Slate
//

import SwiftUI

struct TranscriptSheet: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Transcript")
                    .font(.title2)
                    .bold()
                Text("Coming Soon…")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.medium, .large])
        }
    }
}

#Preview {
    ContentView()
}
