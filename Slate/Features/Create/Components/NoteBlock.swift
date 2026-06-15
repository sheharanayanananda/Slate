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
    var indent: Int
    
    enum BlockType: String, Codable {
        case paragraph
        case header1
        case header2
        case subheading
        case checklist
        case bullet
        case numbered
    }
    
    init(id: String = UUID().uuidString, type: BlockType = .paragraph, content: String = "", isChecked: Bool = false, indent: Int = 0) {
        self.id = id
        self.type = type
        self.content = content
        self.isChecked = isChecked
        self.indent = indent
    }
}

struct NoteBlockParser {
    
    /// Parses a description string (RTF or plain text markdown) into a list of NoteBlock structs
    static func parse(desc: String) -> [NoteBlock] {
        var blocks = [NoteBlock]()
        
        if desc.hasPrefix("rtf:"), let data = Data(base64Encoded: String(desc.dropFirst(4))),
           let attrStr = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil) {
            
            let nsString = attrStr.string as NSString
            var location = 0
            
            while location < nsString.length {
                let searchRange = NSRange(location: location, length: nsString.length - location)
                let newlineRange = nsString.range(of: "\n", options: [], range: searchRange)
                
                let lineRange: NSRange
                if newlineRange.location != NSNotFound {
                    lineRange = NSRange(location: location, length: newlineRange.location - location)
                    location = newlineRange.location + 1
                } else {
                    lineRange = NSRange(location: location, length: nsString.length - location)
                    location = nsString.length
                }
                
                let lineString = nsString.substring(with: lineRange)
                if lineRange.length == 0 {
                    blocks.append(NoteBlock(type: .paragraph, content: "", indent: 0))
                    continue
                }
                
                var blockType: NoteBlock.BlockType = .paragraph
                var isChecked = false
                var indent = 0
                var content = lineString
                
                let attrIndex = lineRange.location
                
                // Get Paragraph style (indentation)
                if let paragraphStyle = attrStr.attribute(.paragraphStyle, at: attrIndex, effectiveRange: nil) as? NSParagraphStyle {
                    indent = Int(round(paragraphStyle.headIndent / 24.0))
                }
                
                // Parse prefix characters
                if content.hasPrefix("☐  ") || content.hasPrefix("☐ ") {
                    blockType = .checklist
                    isChecked = false
                    content = String(content.dropFirst(content.hasPrefix("☐  ") ? 3 : 2))
                } else if content.hasPrefix("☑  ") || content.hasPrefix("☑ ") {
                    blockType = .checklist
                    isChecked = true
                    content = String(content.dropFirst(content.hasPrefix("☑  ") ? 3 : 2))
                } else if content.hasPrefix("•  ") || content.hasPrefix("• ") {
                    blockType = .bullet
                    content = String(content.dropFirst(content.hasPrefix("•  ") ? 3 : 2))
                } else if content.range(of: "^\\d+\\.\\s", options: .regularExpression) != nil {
                    blockType = .numbered
                    if let dotRange = content.range(of: ". ") {
                        content = String(content[dotRange.upperBound...])
                    }
                } else {
                    // Query font properties
                    if let font = attrStr.attribute(.font, at: attrIndex, effectiveRange: nil) as? UIFont {
                        let size = font.pointSize
                        let isBold = font.fontDescriptor.symbolicTraits.contains(.traitBold)
                        
                        if isBold {
                            if size >= 22 {
                                blockType = .header1
                            } else if size >= 19 {
                                blockType = .header2
                            } else if size >= 17 {
                                blockType = .subheading
                            }
                        }
                    }
                }
                
                blocks.append(NoteBlock(type: blockType, content: content, isChecked: isChecked, indent: indent))
            }
        } else {
            // Fallback plain text markdown parser
            var plainText = desc
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
            
            let lines = plainText.components(separatedBy: .newlines)
            for line in lines {
                var indent = 0
                var tempLine = line
                
                while tempLine.hasPrefix("    ") {
                    indent += 1
                    tempLine = String(tempLine.dropFirst(4))
                }
                while tempLine.hasPrefix("\t") {
                    indent += 1
                    tempLine = String(tempLine.dropFirst(1))
                }
                
                let trimmed = tempLine.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    blocks.append(NoteBlock(type: .paragraph, content: "", indent: indent))
                    continue
                }
                
                if trimmed.hasPrefix("```") {
                    continue
                }
                
                if tempLine.hasPrefix("# ") {
                    blocks.append(NoteBlock(type: .header1, content: String(tempLine.dropFirst(2)), indent: indent))
                } else if tempLine.hasPrefix("## ") {
                    blocks.append(NoteBlock(type: .header2, content: String(tempLine.dropFirst(3)), indent: indent))
                } else if tempLine.hasPrefix("### ") {
                    blocks.append(NoteBlock(type: .subheading, content: String(tempLine.dropFirst(4)), indent: indent))
                } else if tempLine.hasPrefix("☐  ") || tempLine.hasPrefix("☐ ") || tempLine.hasPrefix("- [ ] ") {
                    let dropCount = tempLine.hasPrefix("- [ ] ") ? 6 : (tempLine.hasPrefix("☐  ") ? 3 : 2)
                    blocks.append(NoteBlock(type: .checklist, content: String(tempLine.dropFirst(dropCount)), isChecked: false, indent: indent))
                } else if tempLine.hasPrefix("☑  ") || tempLine.hasPrefix("☑ ") || tempLine.hasPrefix("- [x] ") {
                    let dropCount = tempLine.hasPrefix("- [x] ") ? 6 : (tempLine.hasPrefix("☑  ") ? 3 : 2)
                    blocks.append(NoteBlock(type: .checklist, content: String(tempLine.dropFirst(dropCount)), isChecked: true, indent: indent))
                } else if tempLine.hasPrefix("- ") || tempLine.hasPrefix("* ") {
                    blocks.append(NoteBlock(type: .bullet, content: String(tempLine.dropFirst(2)), indent: indent))
                } else if tempLine.range(of: "^\\d+\\.\\s", options: .regularExpression) != nil {
                    if let dotRange = tempLine.range(of: ". ") {
                        let content = String(tempLine[dotRange.upperBound...])
                        blocks.append(NoteBlock(type: .numbered, content: content, indent: indent))
                    } else {
                        blocks.append(NoteBlock(type: .paragraph, content: tempLine, indent: indent))
                    }
                } else {
                    blocks.append(NoteBlock(type: .paragraph, content: tempLine, indent: indent))
                }
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
        var numberedCounts = [Int: Int]()
        
        return blocks.map { block in
            let prefixIndent = String(repeating: "    ", count: block.indent)
            
            // Keep track of numbered list items count per indent level
            if block.type == .numbered {
                let currentCount = (numberedCounts[block.indent] ?? 0) + 1
                numberedCounts[block.indent] = currentCount
            } else {
                // Reset numbered counter for current and deeper indent levels
                for lvl in block.indent...10 {
                    numberedCounts[lvl] = nil
                }
            }
            
            switch block.type {
            case .paragraph:
                return prefixIndent + block.content
            case .header1:
                return prefixIndent + "# " + block.content
            case .header2:
                return prefixIndent + "## " + block.content
            case .subheading:
                return prefixIndent + "### " + block.content
            case .checklist:
                return prefixIndent + (block.isChecked ? "- [x] " : "- [ ] ") + block.content
            case .bullet:
                return prefixIndent + "- " + block.content
            case .numbered:
                let num = numberedCounts[block.indent] ?? 1
                return prefixIndent + "\(num). " + block.content
            }
        }.joined(separator: "\n")
    }
}
