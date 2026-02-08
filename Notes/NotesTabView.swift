//
//  NotesTabView.swift
//  Notes
//
//  Created by Thineth Shehara on 2026-02-07.
//

import SwiftUI

struct NotesTabView: View {
    var body: some View {
        List {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Note Header Here")
                      .font(.system(size: 17))
                    Spacer()
                    Text("07th Feb 2026")
                      .font(.caption)
                }
                Text("Note Description Here and 1234 and nothing no...")
                  .font(.system(size: 12))
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {}
            }
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                Button("Coming Soon", systemImage: "bolt") {}
                        .tint(.accentColor)
            }
        }
        .navigationTitle("Notes")
        .toolbarTitleDisplayMode(.automatic)
    }
}

#Preview {
  ContentView()
}

