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
        case notes, create, intelligence, settings
    }

    @State private var activeTab: TabIdentifier = .notes
    @State private var editingNote: SlateModel? = nil
    @State private var quickFeature: FeatureType? = nil
    @State private var showSettings = false

    @State private var isSettingsVisible = false
    @State private var isSettingsInteractable = false
    @State private var settingsViewModel = SettingsViewModel()

    @Environment(\.modelContext) private var context

    private func settingsXOffset(screenWidth: CGFloat) -> CGFloat {
        if showSettings {
            return 0
        } else {
            return -screenWidth
        }
    }

    //----------------- Start of UI Code -----------------//
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            ZStack {
                TabView(selection: $activeTab) {
                    Tab("Slate", systemImage: "scribble.variable", value: .notes) {
                        NavigationStack {
                            SlateTabView(
                                showSettings: $showSettings,
                                onOpenSettings: {
                                    isSettingsVisible = true
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        showSettings = true
                                    }
                                },
                                onCreate: {
                                    editingNote = nil
                                    activeTab = .create
                                },
                                onSelect: { note in
                                    editingNote = note
                                    activeTab = .create
                                },
                                onSmartLense: { quickFeature = .smartLense },
                                onTranscript: { quickFeature = .transcript }
                            )
                        }
                    }
                    
                    Tab(editingNote == nil ? "New Note" : "Edit Note", systemImage: "plus", value: .create) {
                        NavigationStack {
                            CreateTabView(editingNote: $editingNote, activeTab: $activeTab)
                        }
                    }
                    
                    Tab("Tools", systemImage: "sparkles", value: .intelligence) {
                        NavigationStack {
                            IntelligenceTabView(editingNote: $editingNote, activeTab: $activeTab)
                        }
                    }
                }
                .sheet(item: $quickFeature) { type in
                    FeatureSheet(type: type, editingNote: $editingNote, activeTab: $activeTab)
                }

                if isSettingsVisible {
                    NavigationStack {
                        SettingsView(viewModel: settingsViewModel, onDismiss: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showSettings = false
                            }
                        })
                        .disabled(!isSettingsInteractable)
                    }
                    .offset(x: settingsXOffset(screenWidth: screenWidth))
                    .zIndex(1)
                }
            }
            .onChange(of: showSettings) { oldValue, newValue in
                isSettingsInteractable = false
                if newValue {
                    isSettingsVisible = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        if showSettings {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.prepare()
                            generator.impactOccurred()
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            if showSettings {
                                isSettingsInteractable = true
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        if !showSettings {
                            isSettingsVisible = false
                        }
                    }
                }
            }
        }
    }
    //----------------- End of UI Code -----------------//
}

#Preview {
    ContentView()
}
