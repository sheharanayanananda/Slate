//
//  ToolsTabView.swift
//  Slate
//

import SwiftUI

struct ToolsTabView: View {
    @Binding var editingNote: SlateModel?
    @Binding var activeTab: ContentView.TabIdentifier
    let onSmartLens: () -> Void
    @State private var activeTool: ToolType?
    
    var body: some View {
        ScrollView {
            let columns = [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ]
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(ToolType.allCases) { tool in
                    ToolCard(
                        title: tool.title,
                        subtitle: tool.subtitle,
                        iconName: tool.iconName,
                        iconColor: tool.iconColor,
                        action: {
                            if tool == .smartLens {
                                onSmartLens()
                            } else {
                                activeTool = tool
                            }
                        }
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Tools")
        .sheet(item: $activeTool) { tool in
            ToolSheet(type: tool, editingNote: $editingNote, activeTab: $activeTab)
        }
    }
}

#Preview {
    ContentView()
}
