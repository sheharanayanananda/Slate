//
//  ContentView.swift
//  Notes
//
//  Created by Thineth Shehara on 2026-02-07.
//

import SwiftUI

struct ContentView: View {
    
    enum TabIdentifier: Hashable {
        case notes, create, profile
    }
    
    @State private var activeTab: TabIdentifier = .notes
    @State private var showCreateSheet: Bool = false
    @State private var title: String = ""
    @State private var description: String = ""
    
    var body: some View {
        TabView(selection: $activeTab) {
            Tab("Notes", systemImage: "xmark.triangle.circle.square", value: .notes) {
                NavigationStack {
                    NotesTabView()
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
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            NavigationStack {
                VStack {
                    TextField(text: $description, prompt: Text("Description Here...")) {}
                }
                .padding()
                .frame(maxHeight: .infinity, alignment: .top)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .close) {
                            // cancel logic here
                            showCreateSheet = false
                        }
                    }
                    
                    ToolbarItem(placement: .automatic) {
                        TextField(text: $title, prompt: Text("Title Here")) {}
                            .font(.headline)
                            .fontWeight(.medium)
                            .padding()
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button(role: .confirm) {
                            // creation logic here
                            showCreateSheet = false
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
}

#Preview {
    ContentView()
}
