//
//  ContentView.swift
//  Slate
//
//  Created by Thineth Shehara on 2026-02-07.
//

import SwiftUI
import SwiftData

struct ContentView: View {

    enum TabIdentifier: Hashable {
        case notes, intelligence, settings
    }

    @State private var activeTab: TabIdentifier = .notes
    @State private var editingNote: SlateModel? = nil
    @State private var showCreateSheet = false

    @Environment(\.modelContext) private var context

    //----------------- Start of UI Code -----------------//
    var body: some View {
        TabView(selection: $activeTab) {
            Tab("Slate", systemImage: "scribble.variable", value: .notes) {
                NavigationStack {
                    SlateTabView(
                        onCreate: {
                            editingNote = nil
                            showCreateSheet = true
                        },
                        onSelect: { note in
                            editingNote = note
                            showCreateSheet = true
                        }
                    )
                }
            }
            
            Tab("Tools", systemImage: "sparkles", value: .intelligence) {
                NavigationStack {
                    IntelligenceTabView(editingNote: $editingNote, showCreateSheet: $showCreateSheet, activeTab: $activeTab)
                }
            }
        }
        
        .sheet(isPresented: $showCreateSheet) {
            NavigationStack {
                CreateTabView(editingNote: $editingNote, activeTab: $activeTab)
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showCreateSheet) {
            NavigationStack {
                CreateTabView(editingNote: $editingNote, activeTab: $activeTab)
            }
            .presentationDetents([.medium, .large])
        }
    }
    //----------------- End of UI Code -----------------//
}

#Preview {
    ContentView()
}
