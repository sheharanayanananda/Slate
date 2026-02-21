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
        case notes, create, settings
    }

    @State private var activeTab: TabIdentifier = .notes
    @State private var editingNote: SlateModel? = nil

    @Environment(\.modelContext) private var context

    //----------------- Start of UI Code -----------------//
    var body: some View {
        TabView(selection: $activeTab) {
            Tab("Slate", systemImage: "xmark.triangle.circle.square", value: .notes) {
                NavigationStack {
                    SlateTabView { note in
                        editingNote = note
                        activeTab = .create
                    }
                }
            }

            Tab("Create", systemImage: "plus", value: .create) {
                NavigationStack {
                    CreateTabView(editingNote: $editingNote, activeTab: $activeTab)
                }
            }

            Tab("Settings", systemImage: "gear", value: .settings) {
                NavigationStack {
                    SettingsTabView()
                }
            }
        }
    }
    //----------------- End of UI Code -----------------//
}

#Preview {
    ContentView()
}
