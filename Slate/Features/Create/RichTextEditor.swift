//
//  RichTextEditor.swift
//  Slate
//

import SwiftUI
import UIKit

struct RichTextEditor: UIViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = .preferredFont(forTextStyle: .body)
        textView.backgroundColor = .clear
        textView.allowsEditingTextAttributes = true
        textView.isScrollEnabled = true
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if context.coordinator.isUpdating { return }
        
        let oldBase64 = context.coordinator.lastSyncedString
        guard text != oldBase64 else { return }
        
        context.coordinator.isUpdating = true
        
        if text.hasPrefix("rtf:"), let data = Data(base64Encoded: String(text.dropFirst(4))) {
            if let attr = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil) {
                uiView.attributedText = attr
                // Ensure text color is standard in case user switches dark/light mode
                uiView.textColor = .label
            }
        } else {
            // Markdown fallback or plain text
            let mdOptions = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
            if let attrStr = try? AttributedString(markdown: text, options: mdOptions) {
                let nsAttr = NSMutableAttributedString(attrStr)
                let defaultFont = UIFont.preferredFont(forTextStyle: .body)
                
                nsAttr.enumerateAttribute(.font, in: NSRange(location: 0, length: nsAttr.length), options: []) { font, range, _ in
                    if let oldFont = font as? UIFont {
                        let newFontDescriptor = defaultFont.fontDescriptor.withSymbolicTraits(oldFont.fontDescriptor.symbolicTraits) ?? defaultFont.fontDescriptor
                        let styledFont = UIFont(descriptor: newFontDescriptor, size: defaultFont.pointSize)
                        nsAttr.addAttribute(.font, value: styledFont, range: range)
                    } else {
                        nsAttr.addAttribute(.font, value: defaultFont, range: range)
                    }
                }
                nsAttr.addAttribute(.foregroundColor, value: UIColor.label, range: NSRange(location: 0, length: nsAttr.length))
                uiView.attributedText = nsAttr
            } else {
                uiView.text = text
                uiView.font = .preferredFont(forTextStyle: .body)
                uiView.textColor = .label
            }
        }
        
        context.coordinator.lastSyncedString = text
        context.coordinator.isUpdating = false
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor
        var isUpdating = false
        var lastSyncedString: String = ""

        init(_ parent: RichTextEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            guard !isUpdating else { return }
            isUpdating = true
            
            if let rtfData = try? textView.attributedText.data(from: NSRange(location: 0, length: textView.attributedText.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]) {
                let base64 = "rtf:" + rtfData.base64EncodedString()
                self.lastSyncedString = base64
                parent.text = base64
            }
            
            isUpdating = false
        }
    }
}
