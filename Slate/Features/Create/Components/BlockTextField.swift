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
    @Binding var selectedRange: NSRange?
    var onEnter: () -> Void
    var onDeleteBackward: () -> Void
    var onFocusChanged: (Bool) -> Void
    
    // Accessory Toolbar Callbacks
    var onToggleFormat: (() -> Void)? = nil
    var onToggleChecklist: (() -> Void)? = nil
    var onToggleBullet: (() -> Void)? = nil
    var onToggleNumbered: (() -> Void)? = nil
    var onDecreaseIndent: (() -> Void)? = nil
    var onIncreaseIndent: (() -> Void)? = nil
    var onDismissKeyboard: (() -> Void)? = nil
    
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
        
        // Setup Keyboard Accessory View (Toolbar)
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let formatButton = UIBarButtonItem(
            image: UIImage(systemName: "textformat"),
            style: .plain,
            target: context.coordinator,
            action: #selector(Coordinator.formatTapped)
        )
        
        let checklistButton = UIBarButtonItem(
            image: UIImage(systemName: "checklist"),
            style: .plain,
            target: context.coordinator,
            action: #selector(Coordinator.checklistTapped)
        )
        
        let bulletButton = UIBarButtonItem(
            image: UIImage(systemName: "list.bullet"),
            style: .plain,
            target: context.coordinator,
            action: #selector(Coordinator.bulletTapped)
        )
        
        let numberedButton = UIBarButtonItem(
            image: UIImage(systemName: "list.number"),
            style: .plain,
            target: context.coordinator,
            action: #selector(Coordinator.numberedTapped)
        )
        
        let decreaseButton = UIBarButtonItem(
            image: UIImage(systemName: "decrease.indent"),
            style: .plain,
            target: context.coordinator,
            action: #selector(Coordinator.decreaseTapped)
        )
        
        let increaseButton = UIBarButtonItem(
            image: UIImage(systemName: "increase.indent"),
            style: .plain,
            target: context.coordinator,
            action: #selector(Coordinator.increaseTapped)
        )
        
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let dismissButton = UIBarButtonItem(
            image: UIImage(systemName: "keyboard.chevron.compact.down"),
            style: .plain,
            target: context.coordinator,
            action: #selector(Coordinator.dismissTapped)
        )
        
        toolbar.items = [
            formatButton,
            checklistButton,
            bulletButton,
            numberedButton,
            decreaseButton,
            increaseButton,
            spacer,
            dismissButton
        ]
        
        toolbar.barTintColor = .systemBackground
        toolbar.tintColor = .systemBlue
        
        textView.inputAccessoryView = toolbar
        
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
            
        let parsedAttr: NSAttributedString
        if isStrikethrough {
            let attributedString = NSMutableAttributedString(attributedString: BlockTextField.parseInlineMarkdown(text, font: font, textColor: textColor))
            let range = NSRange(location: 0, length: attributedString.length)
            attributedString.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: range)
            attributedString.addAttribute(.foregroundColor, value: UIColor.secondaryLabel, range: range)
            parsedAttr = attributedString
        } else {
            parsedAttr = BlockTextField.parseInlineMarkdown(text, font: font, textColor: textColor)
        }
        
        let needsUpdate = (uiView.attributedText != parsedAttr) || styleChanged || textChanged
        
        if needsUpdate {
            // Save cursor position
            let selectedRange = uiView.selectedTextRange
            
            uiView.attributedText = parsedAttr
            
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
    
    static func parseInlineMarkdown(_ text: String, font: UIFont, textColor: UIColor) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: text)
        let totalRange = NSRange(location: 0, length: attributedString.length)
        
        // Base styling
        attributedString.addAttribute(.font, value: font, range: totalRange)
        attributedString.addAttribute(.foregroundColor, value: textColor, range: totalRange)
        
        // 1. Bold styling: **text**
        if let boldRegex = try? NSRegularExpression(pattern: "\\*\\*(.*?)\\*\\*", options: []) {
            let matches = boldRegex.matches(in: text, options: [], range: totalRange)
            for match in matches {
                let innerRange = match.range(at: 1)
                if innerRange.location != NSNotFound {
                    let descriptor = font.fontDescriptor.withSymbolicTraits(.traitBold) ?? font.fontDescriptor
                    let boldFont = UIFont(descriptor: descriptor, size: font.pointSize)
                    attributedString.addAttribute(.font, value: boldFont, range: innerRange)
                }
                // Dim the asterisks
                let startAsterisk = NSRange(location: match.range.location, length: 2)
                let endAsterisk = NSRange(location: match.range.location + match.range.length - 2, length: 2)
                attributedString.addAttribute(.foregroundColor, value: UIColor.secondaryLabel.withAlphaComponent(0.35), range: startAsterisk)
                attributedString.addAttribute(.foregroundColor, value: UIColor.secondaryLabel.withAlphaComponent(0.35), range: endAsterisk)
            }
        }
        
        // 2. Italic styling: *text* (avoiding double asterisks)
        if let italicRegex = try? NSRegularExpression(pattern: "(?<!\\*)\\*(?!\\*)(.*?)(?<!\\*)\\*(?!\\*)", options: []) {
            let matches = italicRegex.matches(in: text, options: [], range: totalRange)
            for match in matches {
                let innerRange = match.range(at: 1)
                if innerRange.location != NSNotFound {
                    let descriptor = font.fontDescriptor.withSymbolicTraits(.traitItalic) ?? font.fontDescriptor
                    let italicFont = UIFont(descriptor: descriptor, size: font.pointSize)
                    attributedString.addAttribute(.font, value: italicFont, range: innerRange)
                }
                // Dim the asterisk
                let startAsterisk = NSRange(location: match.range.location, length: 1)
                let endAsterisk = NSRange(location: match.range.location + match.range.length - 1, length: 1)
                attributedString.addAttribute(.foregroundColor, value: UIColor.secondaryLabel.withAlphaComponent(0.35), range: startAsterisk)
                attributedString.addAttribute(.foregroundColor, value: UIColor.secondaryLabel.withAlphaComponent(0.35), range: endAsterisk)
            }
        }
        
        // 3. Strikethrough styling: ~~text~~
        if let strikeRegex = try? NSRegularExpression(pattern: "~~(.*?)~~", options: []) {
            let matches = strikeRegex.matches(in: text, options: [], range: totalRange)
            for match in matches {
                let innerRange = match.range(at: 1)
                if innerRange.location != NSNotFound {
                    attributedString.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: innerRange)
                }
                // Dim the tildes
                let startTilde = NSRange(location: match.range.location, length: 2)
                let endTilde = NSRange(location: match.range.location + match.range.length - 2, length: 2)
                attributedString.addAttribute(.foregroundColor, value: UIColor.secondaryLabel.withAlphaComponent(0.35), range: startTilde)
                attributedString.addAttribute(.foregroundColor, value: UIColor.secondaryLabel.withAlphaComponent(0.35), range: endTilde)
            }
        }
        
        return attributedString
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
        
        @objc func formatTapped() {
            parent.onToggleFormat?()
        }
        
        @objc func checklistTapped() {
            parent.onToggleChecklist?()
        }
        
        @objc func bulletTapped() {
            parent.onToggleBullet?()
        }
        
        @objc func numberedTapped() {
            parent.onToggleNumbered?()
        }
        
        @objc func decreaseTapped() {
            parent.onDecreaseIndent?()
        }
        
        @objc func increaseTapped() {
            parent.onIncreaseIndent?()
        }
        
        @objc func dismissTapped() {
            parent.onDismissKeyboard?()
        }
        
        func textViewDidChange(_ textView: UITextView) {
            lastText = textView.text
            parent.text = textView.text
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            parent.selectedRange = textView.selectedRange
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
