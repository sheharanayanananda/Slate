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
    
    @State private var noteToShare: NotesModel?
    @State private var showShareOptions = false
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []

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
                            Text(note.title.count > 20 ? String(note.title.prefix(20)) + "…" : note.title)
                                .font(.system(size: 17))
                                .truncationMode(.tail)
                            Spacer()
                            Text(note.created_at.formatted(date: .abbreviated, time: .shortened))
                              .font(.caption)
                        }
                        Text(note.desc)
                          .font(.system(size: 12))
                          .lineLimit(4)
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
                    Button("Share", systemImage: "square.and.arrow.up") {
                        noteToShare = note
                        showShareOptions = true
                    }
                    .tint(.accentColor)
                }
            }
        }
        .navigationTitle("Notes")
        .toolbarTitleDisplayMode(.automatic)
        .confirmationDialog("Share Note", isPresented: $showShareOptions, titleVisibility: .visible) {
            Button("Share Content") {
                if let note = noteToShare {
                    let richText = NoteSharingHelper.generateRichText(for: note)
                    shareItems = [richText]
                    showShareSheet = true
                }
            }
            
            Button("Save as PDF") {
                if let note = noteToShare, let pdfURL = NoteSharingHelper.generatePDF(for: note) {
                    shareItems = [pdfURL]
                    showShareSheet = true
                }
            }
            
            Button("Save as Text") {
                if let note = noteToShare, let textURL = NoteSharingHelper.generateTextFile(for: note) {
                    shareItems = [textURL]
                    showShareSheet = true
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: shareItems)
                .presentationDetents([.medium, .large])
        }
    }
}

#Preview {
  ContentView()
}
