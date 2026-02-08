//
//  ContentView.swift
//  Notes
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
    @State private var editingNote: NotesModel? = nil

    @Environment(\.modelContext) private var context

    var body: some View {
        TabView(selection: $activeTab) {
            Tab("Notes", systemImage: "xmark.triangle.circle.square", value: .notes) {
                NavigationStack {
                    NotesTabView { note in
                        // Prefill fields and switch to Create tab for editing
                        editingNote = note
                        activeTab = .create
                    }
                }
            }

            Tab("Create", systemImage: "plus", value: .create) {
                NavigationStack {
                    CreateTabView(editingNote: $editingNote)
                }
            }

            Tab("Profile", systemImage: "person.fill", value: .profile) {
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
