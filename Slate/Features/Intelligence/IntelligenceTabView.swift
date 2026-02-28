//
//  IntelligenceTabView.swift
//  Slate
//
//  Created by Thineth Shehara on 2026-02-21.
//

import SwiftUI

struct IntelligenceTabView: View {
    @Binding var editingNote: SlateModel?
    @Binding var activeTab: ContentView.TabIdentifier
    @State private var activeShortcut: ShortcutType?
    
    //----------------- Start of UI Code -----------------//
    var body: some View {
        NavigationStack {
            ScrollView {
                let columns = [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ]
                
                LazyVGrid(columns: columns, spacing: 16) {
                    ShortcutCard(
                        title: "AI Lense",
                        iconName: "camera.aperture",
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
                    ShortcutCard(
                        title: "Summerize",
                        iconName: "text.pad.header",
                        color: Color(.orange),
                        action: {
                            activeShortcut = .summerize
                        }
                    )
                }
                .sheet(item: $activeShortcut) { type in
                    ShortcutSheet(type: type, editingNote: $editingNote, activeTab: $activeTab)
                }
                .padding()
            }
            .navigationTitle("Intelligence")
        }
    }
    //----------------- End of UI Code -----------------//
}

#Preview {
    ContentView()
}
