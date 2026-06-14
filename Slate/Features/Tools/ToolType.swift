//
//  ToolType.swift
//  Slate
//

import SwiftUI

enum ToolType: String, Identifiable, CaseIterable {
    case smartLens
    case transcribe
    
    var id: String { self.rawValue }
    
    var title: String {
        switch self {
        case .smartLens:
            return "Smart Lens"
        case .transcribe:
            return "Transcribe"
        }
    }
    
    var subtitle: String {
        switch self {
        case .smartLens:
            return "Capture and convert real-world text or objects into intelligent notes."
        case .transcribe:
            return "Transcribe voice memos and audio recordings into smart transcripts."
        }
    }
    
    var iconName: String {
        switch self {
        case .smartLens:
            return "text.viewfinder"
        case .transcribe:
            return "waveform"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .smartLens:
            return .blue
        case .transcribe:
            return .pink
        }
    }
}
