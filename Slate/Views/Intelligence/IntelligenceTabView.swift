//
//  IntelligenceTabView.swift
//  Slate
//
//  Created by Thineth Shehara on 2026-02-21.
//

import SwiftUI

struct IntelligenceTabView: View {
    //----------------- Start of UI Code -----------------//
    var body: some View {
        List {
            Section(header: Text("AI Features")) {
                Button(action: {
                    // Placeholder for Image to Intelligent Notes
                }) {
                    HStack {
                        Image(systemName: "photo.badge.plus.fill")
                            .foregroundColor(.blue)
                        Text("Image to Intelligent Notes")
                            .foregroundColor(.primary)
                    }
                }
                
                Button(action: {
                    // Placeholder for Conversation Transcript Gen
                }) {
                    HStack {
                        Image(systemName: "mic.and.signal.meter.fill")
                            .foregroundColor(.purple)
                        Text("Conversation Transcript Gen")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .navigationTitle("Intelligence")
    }
    //----------------- End of UI Code -----------------//
}

#Preview {
    NavigationStack {
        IntelligenceTabView()
    }
}
