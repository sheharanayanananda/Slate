//
//  SummarizeSheet.swift
//  Slate
//

import SwiftUI

struct SummarizeSheet: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Summarize")
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
