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
    @Binding var showSettings: Bool
    @State private var shareItems: [Any] = []

    let onCreate: () -> Void
    let onSelect: (SlateModel) -> Void
    let onSmartLense: () -> Void
    let onTranscript: () -> Void

    init(
        showSettings: Binding<Bool>,
        onCreate: @escaping () -> Void = {},
        onSelect: @escaping (SlateModel) -> Void = { _ in },
        onSmartLense: @escaping () -> Void = {},
        onTranscript: @escaping () -> Void = {}
    ) {
        self._showSettings = showSettings
        self.onCreate = onCreate
        self.onSelect = onSelect
        self.onSmartLense = onSmartLense
        self.onTranscript = onTranscript
    }

    //----------------- Start of UI Code -----------------//
    var body: some View {
        ZStack {
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
                        systemImage: "scribble.variable",
                        description: Text("Let's slate down something useful!")
                    )
                }
            }
        }
        .navigationTitle("Slate")
        .toolbarTitleDisplayMode(.automatic)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 16) {
                    Button("Transcript", systemImage: "mic") {
                        onTranscript()
                    }
                    Button("Smart Lense", systemImage: "camera") {
                        onSmartLense()
                    }
                }
            }
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showSettings = true
                    }
                }) {
                    Image(systemName: "gear")
                }
            }
        }
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
