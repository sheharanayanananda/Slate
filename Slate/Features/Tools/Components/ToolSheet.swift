//
//  ToolSheet.swift
//  Slate
//

import SwiftUI

struct ToolSheet: View {
    let type: ToolType
    @Binding var editingNote: SlateModel?
    @Binding var activeTab: ContentView.TabIdentifier
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            switch type {
            case .smartLens:
                EmptyView()
            case .transcribe:
                TranscribeToolSheet()
            }
        }
    }
}

#Preview {
    ContentView()
}
