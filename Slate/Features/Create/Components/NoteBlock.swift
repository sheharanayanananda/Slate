//
//  NoteBlock.swift
//  Slate
//

import Foundation
import UIKit

struct NoteBlock: Identifiable, Hashable, Equatable {
    let id: String
    var type: BlockType
    var content: String
    var isChecked: Bool
    
    enum BlockType: String, Codable {
        case paragraph
        case header1
        case header2
        case checklist
    }
    
    init(id: String = UUID().uuidString, type: BlockType = .paragraph, content: String = "", isChecked: Bool = false) {
        self.id = id
        self.type = type
        self.content = content
        self.isChecked = isChecked
    }
}

struct NoteBlockParser {
    
    /// Parses a description string (RTF or plain text markdown) into a list of NoteBlock structs
    static func parse(desc: String) -> [NoteBlock] {
        var plainText = desc
        
        // If it is encoded as RTF, convert it to plain text first
        if desc.hasPrefix("rtf:"), let data = Data(base64Encoded: String(desc.dropFirst(4))),
           let attr = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil) {
            plainText = attr.string
        } else {
            // Strip markdown block symbols at the beginning/end if this is raw text from Ollama
            var textToParse = plainText.trimmingCharacters(in: .whitespacesAndNewlines)
            if let blockRange = textToParse.range(of: "```markdown") {
                let afterBlock = textToParse[blockRange.upperBound...]
                if let endBlockRange = afterBlock.range(of: "```") {
                    textToParse = String(afterBlock[..<endBlockRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                } else {
                    textToParse = String(afterBlock).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            } else if let blockRange = textToParse.range(of: "```") {
                let afterBlock = textToParse[blockRange.upperBound...]
                if let endBlockRange = afterBlock.range(of: "```") {
                    textToParse = String(afterBlock[..<endBlockRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                } else {
                    textToParse = String(afterBlock).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            plainText = textToParse
        }
        
        let lines = plainText.components(separatedBy: .newlines)
        var blocks = [NoteBlock]()
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                // Keep empty lines as paragraph blocks to preserve spacing
                blocks.append(NoteBlock(type: .paragraph, content: ""))
                continue
            }
            
            if trimmed.hasPrefix("```") {
                continue
            }
            
            if line.hasPrefix("# ") {
                blocks.append(NoteBlock(type: .header1, content: String(line.dropFirst(2))))
            } else if line.hasPrefix("## ") {
                blocks.append(NoteBlock(type: .header2, content: String(line.dropFirst(3))))
            } else if line.hasPrefix("### ") {
                blocks.append(NoteBlock(type: .header2, content: String(line.dropFirst(4))))
            } else if line.hasPrefix("☐  ") || line.hasPrefix("☐ ") || line.hasPrefix("- [ ] ") {
                let dropCount = line.hasPrefix("- [ ] ") ? 6 : (line.hasPrefix("☐  ") ? 3 : 2)
                blocks.append(NoteBlock(type: .checklist, content: String(line.dropFirst(dropCount)), isChecked: false))
            } else if line.hasPrefix("☑  ") || line.hasPrefix("☑ ") || line.hasPrefix("- [x] ") {
                let dropCount = line.hasPrefix("- [x] ") ? 6 : (line.hasPrefix("☑  ") ? 3 : 2)
                blocks.append(NoteBlock(type: .checklist, content: String(line.dropFirst(dropCount)), isChecked: true))
            } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
                // Bullet points: treat as paragraph blocks containing the prefix bullet for now, or clean up if desired
                blocks.append(NoteBlock(type: .paragraph, content: line))
            } else {
                blocks.append(NoteBlock(type: .paragraph, content: line))
            }
        }
        
        // Ensure we always have at least one edit block
        if blocks.isEmpty {
            blocks.append(NoteBlock(type: .paragraph, content: ""))
        }
        
        return blocks
    }
    
    /// Serializes list of NoteBlock elements to raw Markdown format
    static func serializeToMarkdown(blocks: [NoteBlock]) -> String {
        return blocks.map { block in
            switch block.type {
            case .paragraph:
                return block.content
            case .header1:
                return "# " + block.content
            case .header2:
                return "## " + block.content
            case .checklist:
                return (block.isChecked ? "- [x] " : "- [ ] ") + block.content
            }
        }.joined(separator: "\n")
    }
}
