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
    
    // Vibrant icon colors
    private let smartLenseIconColor = Color.blue
    private let transcriptIconColor = Color.pink
    private let summarizeIconColor = Color.orange
    
    //----------------- Start of UI Code -----------------//
    var body: some View {
        ScrollView {
            let columns = [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ]
            
            LazyVGrid(columns: columns, spacing: 16) {
                FeatureCard(
                    title: "Smart Lense",
                    iconName: "sparkles",
                    iconColor: smartLenseIconColor,
                    action: {
                        activeFeature = .smartLense
                    }
                )
                FeatureCard(
                    title: "Transcript",
                    iconName: "waveform",
                    iconColor: transcriptIconColor,
                    action: {
                        activeFeature = .transcript
                    }
                )
                FeatureCard(
                    title: "Summarize",
                    iconName: "list.bullet.below.rectangle",
                    iconColor: summarizeIconColor,
                    action: {
                        activeFeature = .summarize
                    }
                )
            }
            .padding()
        }
        .navigationTitle("Tools")
        .sheet(item: $activeFeature) { type in
            FeatureSheet(type: type, editingNote: $editingNote, activeTab: $activeTab)
        }
    }
    //----------------- End of UI Code -----------------//
}

#Preview {
    ContentView()
}
