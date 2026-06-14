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
    @State private var settingsDragOffset: CGFloat = 0
    @State private var settingsViewModel = SettingsViewModel()

    @Environment(\.modelContext) private var context

    private func settingsXOffset(screenWidth: CGFloat) -> CGFloat {
        if showSettings {
            return min(0, settingsDragOffset)
        } else {
            return min(0, -screenWidth + settingsDragOffset)
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
                .onSwipeRightToOpen(
                    isEnabled: !showSettings && activeTab == .notes,
                    onDragChanged: { translation in
                        if translation > 0 {
                            settingsDragOffset = translation
                        }
                    },
                    onDragEnded: { translation, velocity in
                        if settingsDragOffset > 0 {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                if translation > screenWidth / 3 || velocity > 500 {
                                    showSettings = true
                                }
                                settingsDragOffset = 0
                            }
                        }
                    }
                )
                
                if showSettings || settingsDragOffset > 0 {
                    NavigationStack {
                        SettingsView(viewModel: settingsViewModel, onDismiss: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showSettings = false
                            }
                        })
                        .disabled(settingsDragOffset != 0)
                    }
                    .offset(x: settingsXOffset(screenWidth: screenWidth))
                    .zIndex(1)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 10)
                            .onChanged { value in
                                if value.translation.width < 0 {
                                    settingsDragOffset = value.translation.width
                                }
                            }
                            .onEnded { value in
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    let predictedEnd = value.predictedEndTranslation.width
                                    if value.translation.width < -screenWidth / 3 || predictedEnd < -screenWidth / 2 {
                                        showSettings = false
                                    }
                                    settingsDragOffset = 0
                                }
                            }
                    )
                }
            }
            .onChange(of: showSettings) { oldValue, newValue in
                if newValue {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.prepare()
                    generator.impactOccurred()
                }
            }
        }
    }
    //----------------- End of UI Code -----------------//
}

#Preview {
    ContentView()
}
