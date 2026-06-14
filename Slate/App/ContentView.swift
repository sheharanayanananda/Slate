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
        case notes, create, intelligence, settings
    }

    @State private var activeTab: TabIdentifier = .notes
    @State private var editingNote: SlateModel? = nil
    @State private var quickFeature: FeatureType? = nil

    @Environment(\.modelContext) private var context

    //----------------- Start of UI Code -----------------//
    var body: some View {
        TabView(selection: $activeTab) {
            Tab("Slate", systemImage: "scribble.variable", value: .notes) {
                NavigationStack {
                    SlateTabView(
                        onCreate: {
                            editingNote = nil
                            activeTab = .create
                        },
                        onSelect: { note in
                            editingNote = note
                            activeTab = .create
                        },
                        onSmartLense: { quickFeature = .smartLense },
                        onTranscript: { quickFeature = .transcript }
                    )
                }
            }
            
            Tab(editingNote == nil ? "New Note" : "Edit Note", systemImage: "plus", value: .create) {
                NavigationStack {
                    CreateTabView(editingNote: $editingNote, activeTab: $activeTab)
                }
            }
            
            Tab("Tools", systemImage: "sparkles", value: .intelligence) {
                NavigationStack {
                    IntelligenceTabView(editingNote: $editingNote, activeTab: $activeTab)
                }
            }
        }
        .sheet(item: $quickFeature) { type in
            FeatureSheet(type: type, editingNote: $editingNote, activeTab: $activeTab)
        }
    }
    //----------------- End of UI Code -----------------//
}

#Preview {
    ContentView()
}
