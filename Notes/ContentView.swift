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
    @State private var showCreateSheet: Bool = false
    @State private var title: String = ""
    @State private var desc: String = ""
    @State private var editingNote: NotesModel? = nil
    @State private var selectedDetent: PresentationDetent = .medium
    
    @Environment(\.modelContext) private var context
    
    var body: some View {
        TabView(selection: $activeTab) {
            Tab("Notes", systemImage: "xmark.triangle.circle.square", value: .notes) {
                NavigationStack {
                    NotesTabView { note in
                        // Prefill fields and open sheet for editing
                        editingNote = note
                        title = note.title
                        desc = note.desc
                        showCreateSheet = true
                    }
                }
            }
            
            Tab("Create", systemImage: "plus", value: .create) {
                // Empty view as this tab acts as a button
                Color.clear
            }
            
            Tab("Profile", systemImage: "person.fill", value: .profile) {
                NavigationStack {
                    ProfileTabView()
                }
            }
        }
        .onChange(of: activeTab) { oldValue, newValue in
            if newValue == .create {
                showCreateSheet = true
                activeTab = oldValue
                editingNote = nil
                title = ""
                desc = ""
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            NavigationStack {
                VStack(spacing: 20) {
                    TextField("Title Here", text: $title)
                        .font(.title3)
                        .padding(.horizontal, 5)
                    TextEditor(text: $desc)
                        .frame(minHeight: 160)
                        .scrollContentBackground(selectedDetent == .medium ? .hidden : .visible)
                        .overlay(alignment: .topLeading) {
                            if desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text("Try n try one day u can fly ✌🏻")
                                    .foregroundStyle(.secondary)
                                    .opacity(0.4)
                                    .padding(.horizontal, 5)
                                    .padding(.top, 8)
                                    .allowsHitTesting(false)
                                    .animation(nil, value: selectedDetent)
                            }
                        }
                }
                .padding()
                .frame(maxHeight: .infinity, alignment: .top)
                .navigationTitle(editingNote == nil ? "New Note" : "Edit Note")
                .toolbarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", systemImage: "xmark", role: .cancel) {
                            reset()
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save", systemImage: "checkmark", role: .confirm) {
                            let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                            let trimmedDesc = desc.trimmingCharacters(in: .whitespacesAndNewlines)
                            if let note = editingNote {
                                // Update existing note
                                note.title = trimmedTitle
                                note.desc = trimmedDesc
                            } else {
                                // Create new note
                                addNote(title: trimmedTitle, desc: trimmedDesc)
                            }
                            reset()
                        }
                        .keyboardShortcut(.defaultAction)
                    }
                }
            }
            .presentationDetents([.medium, .large], selection: $selectedDetent)
        }
    }

    func addNote(title: String, desc: String) {
        let note = NotesModel(title: title, desc: desc)
        context.insert(note)
    }
    
    func reset() {
        title = ""
        desc = ""
        
        editingNote = nil
        showCreateSheet = false
    }
}

#Preview {
    ContentView()
}

