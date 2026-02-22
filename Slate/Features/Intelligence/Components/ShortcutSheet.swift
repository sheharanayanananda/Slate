//
//  ShortcutSheet.swift
//  Slate
//

import SwiftUI

enum ShortcutType: Identifiable {
    case imageToNote
    case transcript
    
    var id: Self { self }
}

struct ShortcutSheet: View {
    let type: ShortcutType
    
    var body: some View {
        VStack(spacing: 16) {
            switch type {
            case .imageToNote:
                Text("Image To Note")
                    .font(.title2)
                    .bold()
                Text("Coming soon…")
                    .foregroundStyle(.secondary)
            case .transcript:
                Text("Transcript")
                    .font(.title2)
                    .bold()
                Text("Coming soon…")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    ShortcutSheet(type: .imageToNote)
}
