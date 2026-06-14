//
//  BlockTextField.swift
//  Slate
//

import SwiftUI
import UIKit

class CustomTextView: UITextView {
    var onDeleteBackward: (() -> Void)?
    
    override func deleteBackward() {
        let wasEmpty = text.isEmpty
        super.deleteBackward()
        if wasEmpty {
            onDeleteBackward?()
        }
    }
}

struct BlockTextField: UIViewRepresentable {
    @Binding var text: String
    var isFocused: Bool
    var font: UIFont
    var textColor: UIColor
    var isStrikethrough: Bool
    var onEnter: () -> Void
    var onDeleteBackward: () -> Void
    var onFocusChanged: (Bool) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> CustomTextView {
        let textView = CustomTextView()
        textView.delegate = context.coordinator
        textView.onDeleteBackward = onDeleteBackward
        textView.backgroundColor = .clear
        textView.isScrollEnabled = false // Allows height to wrap to content length
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        
        textView.font = font
        textView.textColor = textColor
        return textView
    }
    
    func updateUIView(_ uiView: CustomTextView, context: Context) {
        let coordinator = context.coordinator
        
        // Update callbacks
        uiView.onDeleteBackward = onDeleteBackward
        
        let textChanged = (text != coordinator.lastText)
        let styleChanged = (isStrikethrough != coordinator.lastIsStrikethrough) 
            || (font != coordinator.lastFont) 
            || (textColor != coordinator.lastTextColor)
        
        if textChanged || styleChanged {
            // Save cursor position
            let selectedRange = uiView.selectedTextRange
            
            if isStrikethrough {
                let attributedString = NSMutableAttributedString(string: text)
                let range = NSRange(location: 0, length: attributedString.length)
                attributedString.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: range)
                attributedString.addAttribute(.foregroundColor, value: UIColor.secondaryLabel, range: range)
                attributedString.addAttribute(.font, value: font, range: range)
                uiView.attributedText = attributedString
            } else {
                uiView.attributedText = nil
                uiView.text = text
                uiView.font = font
                uiView.textColor = textColor
            }
            
            coordinator.lastText = text
            coordinator.lastIsStrikethrough = isStrikethrough
            coordinator.lastFont = font
            coordinator.lastTextColor = textColor
            
            // Restore cursor position
            if let selectedRange = selectedRange {
                uiView.selectedTextRange = selectedRange
            }
        }
        
        // Handle Focus state
        if isFocused && !uiView.isFirstResponder {
            DispatchQueue.main.async {
                uiView.becomeFirstResponder()
            }
        } else if !isFocused && uiView.isFirstResponder {
            DispatchQueue.main.async {
                uiView.resignFirstResponder()
            }
        }
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: BlockTextField
        var lastText: String = ""
        var lastIsStrikethrough: Bool = false
        var lastFont: UIFont? = nil
        var lastTextColor: UIColor? = nil
        
        init(_ parent: BlockTextField) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            lastText = textView.text
            parent.text = textView.text
        }
        
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if text == "\n" {
                parent.onEnter()
                return false
            }
            return true
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.onFocusChanged(true)
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            parent.onFocusChanged(false)
        }
    }
}
