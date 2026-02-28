//
//  SlateTabView.swift
//  Slate
//
//  Created by Thineth Shehara on 2026-02-07.
//

import SwiftUI
import SwiftData

struct SlateTabView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SlateModel.created_at, order: .reverse) private var notes: [SlateModel]
    
    @State private var noteToShare: SlateModel?
    @State private var showShareOptions = false
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []

    let onSelect: (SlateModel) -> Void

    init(onSelect: @escaping (SlateModel) -> Void = { _ in }) {
        self.onSelect = onSelect
    }

    //----------------- Start of UI Code -----------------//
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
                        Text(note.previewText)
                          .font(.system(size: 12))
                          .lineLimit(4)
                          .lineHeight(.loose)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        context.delete(note)
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button("Share", systemImage: "square.and.arrow.up") {
                        noteToShare = note
                        showShareOptions = true
                    }
                    .tint(.accentColor)
                }
                .confirmationDialog("Share Slate", isPresented: Binding(
                    get: { showShareOptions && noteToShare == note },
                    set: { if !$0 { showShareOptions = false; noteToShare = nil } }
                ), titleVisibility: .visible) {
                    Button("Share Richtext") {
                        let itemSource = NoteItemSource(note: note)
                        shareItems = [itemSource]
                        showShareSheet = true
                    }
                    
                    Button("Save as PDF") {
                        if let pdfURL = NoteSharingHelper.generatePDF(for: note) {
                            shareItems = [pdfURL]
                            showShareSheet = true
                        }
                    }
                    
                    Button("Save as Text") {
                        if let textURL = NoteSharingHelper.generateTextFile(for: note) {
                            shareItems = [textURL]
                            showShareSheet = true
                        }
                    }
                }
            }
        }
        .overlay {
            if notes.isEmpty {
                ContentUnavailableView(
                    "Hello !",
                    systemImage: "sparkles",
                    description: Text("Let's slate down something useful!")
                )
                // If you want broader OS support, see the fallback below
            }
        }
        .navigationTitle("Slate")
        .toolbarTitleDisplayMode(.automatic)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: shareItems)
                .presentationDetents([.medium, .large])
        }
    }
    //----------------- End of UI Code -----------------//
}

#Preview {
  ContentView()
}
