//
//  IntelligenceTabView.swift
//  Slate
//
//  Created by Thineth Shehara on 2026-02-21.
//

import SwiftUI

struct IntelligenceTabView: View {
    @State private var activeShortcut: ShortcutType?
    
    //----------------- Start of UI Code -----------------//
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ShortcutCard(
                                title: "Image To Note",
                                iconName: "text.viewfinder",
                                color: Color(.blue),
                                action: {
                                    activeShortcut = .imageToNote
                                }
                            )
                            ShortcutCard(
                                title: "Transcript",
                                iconName: "waveform",
                                color: Color(.pink),
                                action: {
                                    activeShortcut = .transcript
                                }
                            )
                        }
                        .sheet(item: $activeShortcut) { type in
                            ShortcutSheet(type: type)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Intelligence")
        }
    }
    //----------------- End of UI Code -----------------//
}

#Preview {
    ContentView()
}
