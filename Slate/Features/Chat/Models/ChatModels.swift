//
//  ChatModels.swift
//  Slate
//
//  Created by Antigravity on 2026-07-14.
//

import Foundation

struct OllamaDocumentAttachment: Codable, Equatable, Hashable, Identifiable {
    var id = UUID()
    let name: String
    let contentText: String
    
    enum CodingKeys: String, CodingKey {
        case name, contentText
    }
    
    init(id: UUID = UUID(), name: String, contentText: String) {
        self.id = id
        self.name = name
        self.contentText = contentText
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.contentText = try container.decode(String.self, forKey: .contentText)
        self.id = UUID()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(contentText, forKey: .contentText)
    }
}

struct OllamaChatMessage: Codable, Equatable, Identifiable {
    var id: String = UUID().uuidString
    let role: String      // "user", "assistant", "system"
    let content: String
    var images: [String]? // Base64 encoded JPEG representations
    var documents: [OllamaDocumentAttachment]?
    var genuiState: String? // Persistent interactive state
    
    enum CodingKeys: String, CodingKey {
        case role, content, images, documents, genuiState
    }
    
    init(id: String = UUID().uuidString, role: String, content: String, images: [String]? = nil, documents: [OllamaDocumentAttachment]? = nil, genuiState: String? = nil) {
        self.id = id
        self.role = role
        self.content = content
        self.images = images
        self.documents = documents
        self.genuiState = genuiState
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.role = try container.decode(String.self, forKey: .role)
        self.content = try container.decode(String.self, forKey: .content)
        self.images = try container.decodeIfPresent([String].self, forKey: .images)
        self.documents = try container.decodeIfPresent([OllamaDocumentAttachment].self, forKey: .documents)
        self.genuiState = try container.decodeIfPresent(String.self, forKey: .genuiState)
        self.id = UUID().uuidString
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(role, forKey: .role)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(images, forKey: .images)
        try container.encodeIfPresent(documents, forKey: .documents)
        try container.encodeIfPresent(genuiState, forKey: .genuiState)
    }
}

enum MemoryLimit: Int, Comparable, CaseIterable, Identifiable {
    case short = 4096      // 4K
    case standard = 8192   // 8K
    case detailed = 16384  // 16K
    case maximum = 32768   // 32K
    
    var id: Int { self.rawValue }
    
    var displayName: String {
        switch self {
        case .short: return "Short (4K)"
        case .standard: return "Standard (8K)"
        case .detailed: return "Detailed (16K)"
        case .maximum: return "Maximum (32K)"
        }
    }
    
    var subLabel: String {
        switch self {
        case .short: return "For quick, simple chats"
        case .standard: return "Good for most tasks"
        case .detailed: return "Better for referencing multiple notes"
        case .maximum: return "Remembers extremely long chats"
        }
    }
    
    static func < (lhs: MemoryLimit, rhs: MemoryLimit) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

enum ChatPreset: String, CaseIterable, Identifiable {
    case slateFlash    = "Slate Flash"
    case slateCreative = "Slate Creative"
    case slatePro      = "Slate Pro"

    // MARK: - Codable (resilient — maps retired cases to successors)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        switch raw {
        case "Slate Flash", "Slate Lite":
            self = .slateFlash
        case "Slate Creative":
            self = .slateCreative
        case "Slate Pro", "Slate Scholar", "Slate Coder":
            self = .slatePro
        default:
            self = .slateFlash
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }

    // MARK: - Identifiable

    var id: String { self.rawValue }

    // MARK: - Display

    var title: String { self.rawValue }

    var modelTierName: String {
        switch self {
        case .slateFlash:    return "Flash"
        case .slateCreative: return "Creative"
        case .slatePro:      return "Pro"
        }
    }

    var shortName: String { self.rawValue }

    var subtitle: String {
        switch self {
        case .slateFlash:    return "Quick answers, note cleanup, daily tasks"
        case .slateCreative: return "Brainstorming, writing, ideation"
        case .slatePro:      return "Deep reasoning, code, math & long docs"
        }
    }

    var iconName: String {
        switch self {
        case .slateFlash:    return "bolt.fill"
        case .slateCreative: return "paintpalette.fill"
        case .slatePro:      return "brain.head.profile"
        }
    }

    // MARK: - AI Configuration

    var systemPrompt: String {
        SystemPrompts.chatPresetPrompt(for: self)
    }

    var creativity: Double {
        switch self {
        case .slateFlash:    return 0.25
        case .slateCreative: return 0.85
        case .slatePro:      return 0.15
        }
    }

    var memorySize: MemoryLimit {
        switch self {
        case .slateFlash:    return .standard  // 8K
        case .slateCreative: return .detailed  // 16K
        case .slatePro:      return .maximum   // 32K
        }
    }

    var thinkingLevel: String {
        switch self {
        case .slateFlash:    return "off"
        case .slateCreative: return "off"
        case .slatePro:      return "high"
        }
    }
}

// MARK: - Codable conformance (satisfies Codable requirement from ChatSession)
extension ChatPreset: Codable {}

