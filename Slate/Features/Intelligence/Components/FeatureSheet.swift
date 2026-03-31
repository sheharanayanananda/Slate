//
//  FeatureSheet.swift
//  Slate
//

import SwiftUI

enum FeatureType: Identifiable {
    case smartLense
    case transcript
    case summarize
    
    var id: Self { self }
}

struct FeatureSheet: View {
    let type: FeatureType
    @Binding var editingNote: SlateModel?
    @Binding var showCreateSheet: Bool
    @Binding var activeTab: ContentView.TabIdentifier
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            switch type {
            case .smartLense:
                SmartLenseSheet(editingNote: $editingNote, showCreateSheet: $showCreateSheet, activeTab: $activeTab)
            case .transcript:
                TranscriptSheet()
            case .summarize:
                SummarizeSheet()
            }
        }
    }
}

#Preview {
    ContentView()
}
