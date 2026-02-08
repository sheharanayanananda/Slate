//
//  NotesTabView.swift
//  Notes
//
//  Created by Thineth Shehara on 2026-02-07.
//

import SwiftUI
import SwiftData

struct NotesTabView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \NotesModel.created_at, order: .reverse) private var notes: [NotesModel]

    let onSelect: (NotesModel) -> Void

    init(onSelect: @escaping (NotesModel) -> Void = { _ in }) {
        self.onSelect = onSelect
    }

    var body: some View {
        List {
            ForEach(notes) { note in
                Button {
                    onSelect(note)
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(note.title)
                              .font(.system(size: 17))
                            Spacer()
                            Text(note.created_at.formatted(date: .abbreviated, time: .shortened))
                              .font(.caption)
                        }
                        Text(note.desc)
                          .font(.system(size: 12))
                          .lineHeight(.loose)
                    }
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        context.delete(note)
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button("Coming Soon", systemImage: "bolt") {}
                            .tint(.accentColor)
                }
            }
        }
        .navigationTitle("Notes")
        .toolbarTitleDisplayMode(.automatic)
    }
}

#Preview {
  ContentView()
}
