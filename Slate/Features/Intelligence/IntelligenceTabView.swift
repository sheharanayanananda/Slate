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
    @State private var activeFeature: FeatureType?
    
    //----------------- Start of UI Code -----------------//
    var body: some View {
        NavigationStack {
            ScrollView {
                let columns = [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ]
                
                LazyVGrid(columns: columns, spacing: 16) {
                    FeatureCard(
                        title: "Smart Lense",
                        iconName: "sparkles",
                        color: Color(.blue),
                        action: {
                            activeFeature = .smartLense
                        }
                    )
                    FeatureCard(
                        title: "Transcript",
                        iconName: "waveform",
                        color: Color(.pink),
                        action: {
                            activeFeature = .transcript
                        }
                    )
                    FeatureCard(
                        title: "Summarize",
                        iconName: "list.bullet.below.rectangle",
                        color: Color(.orange),
                        action: {
                            activeFeature = .summarize
                        }
                    )
                }
                .sheet(item: $activeFeature) { type in
                    FeatureSheet(type: type, editingNote: $editingNote, activeTab: $activeTab)
                }
                .padding()
            }
            .navigationTitle("Intelligence")
        }
    }
    //----------------- End of UI Code -----------------//
}

#Preview {
    IntelligenceTabView(
        editingNote: .constant(nil),
        activeTab: .constant(.intelligence)
    )
}
