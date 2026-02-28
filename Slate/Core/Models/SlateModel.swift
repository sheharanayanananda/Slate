//
//  SlateModel.swift
//  Slate
//
//  Created by Thineth Shehara on 2026-02-08.
//

import Foundation
import SwiftData

@Model
final class SlateModel: Identifiable {
    @Attribute(.unique) var id: String
    var title: String
    var desc: String
    var created_at: Date

    init(id: String = UUID().uuidString, title: String, desc: String, created_at: Date = .now) {
        self.id = id
        self.title = title
        self.desc = desc
        self.created_at = created_at
    }
}

import UIKit

extension SlateModel {
    var attributedDesc: NSAttributedString {
        if desc.hasPrefix("rtf:"), let data = Data(base64Encoded: String(desc.dropFirst(4))),
           let attr = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil) {
            return attr
        }
        
        let mdOptions = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        if let attrStr = try? AttributedString(markdown: desc, options: mdOptions) {
            return NSAttributedString(attrStr)
        }
        
        return NSAttributedString(string: desc)
    }
    
    var previewText: String {
        return attributedDesc.string
    }
}
