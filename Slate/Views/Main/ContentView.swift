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
        case notes, create, profile
    }

    @State private var activeTab: TabIdentifier = .notes
    @State private var editingNote: SlateModel? = nil

    @Environment(\.modelContext) private var context

    var body: some View {
        TabView(selection: $activeTab) {
            Tab("Slate", systemImage: "xmark.triangle.circle.square", value: .notes) {
                NavigationStack {
                    SlateTabView { note in
                        // Prefill fields and switch to Create tab for editing
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

            Tab("Settings", systemImage: "gear", value: .profile) {
                NavigationStack {
                    ProfileTabView()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
