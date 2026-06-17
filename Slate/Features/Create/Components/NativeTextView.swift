//
//  NativeTextView.swift
//  Slate
//

import SwiftUI
import UIKit

extension NSTextContainer {
    var textStorage: NSTextStorage? {
        if let lm = self.layoutManager {
            return lm.textStorage
        }
        if let tlm = self.textLayoutManager,
           let tcs = tlm.textContentManager as? NSTextContentStorage {
            return tcs.textStorage
        }
        return nil
    }
}

class CheckboxAttachment: NSTextAttachment {
    var isChecked: Bool
    
    init(isChecked: Bool) {
        self.isChecked = isChecked
        super.init(data: nil, ofType: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func image(forBounds imageBounds: CGRect, textContainer: NSTextContainer?, characterIndex charIndex: Int) -> UIImage? {
        guard let textStorage = textContainer?.textStorage else { return nil }
        
        let font: UIFont
        var range = NSRange(location: 0, length: 0)
        if charIndex < textStorage.length,
           let f = textStorage.attribute(NSAttributedString.Key.font, at: charIndex, effectiveRange: &range) as? UIFont {
            font = f
        } else {
            font = UIFont.preferredFont(forTextStyle: .body)
        }
        
        let config = UIImage.SymbolConfiguration(font: font)
        let systemName = isChecked ? "checkmark.circle.fill" : "circle"
        let color = isChecked ? UIColor.systemBlue : UIColor.tertiaryLabel
        return UIImage(systemName: systemName, withConfiguration: config)?.withTintColor(color, renderingMode: .alwaysOriginal)
    }
    
    override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        guard let textStorage = textContainer?.textStorage else {
            return CGRect(x: 0, y: -4, width: 22, height: 22)
        }
        
        let font: UIFont
        var range = NSRange(location: 0, length: 0)
        if charIndex < textStorage.length,
           let f = textStorage.attribute(NSAttributedString.Key.font, at: charIndex, effectiveRange: &range) as? UIFont {
            font = f
        } else {
            font = UIFont.preferredFont(forTextStyle: .body)
        }
        
        // Checklist size dynamically scaled to 95% of font line height
        let size = font.lineHeight * 0.95
        // Centered relative to the cap height of the text
        let yOffset = (font.capHeight - size) / 2
        return CGRect(x: 0, y: yOffset, width: size, height: size)
    }
}

struct NativeKeyboardToolbar: View {
    var onToggleChecklist: () -> Void
    var onDismissKeyboard: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onToggleChecklist) {
                Image(systemName: "checklist")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
            }
            .background(Color(.systemGray6))
            .clipShape(Circle())
            
            Spacer()
            
            Button(action: onDismissKeyboard) {
                Image(systemName: "keyboard.chevron.compact.down")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
            }
            .background(Color(.systemGray6))
            .clipShape(Circle())
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
        .background(Color.clear)
    }
}

struct NativeTextView: UIViewRepresentable {
    @Binding var text: String
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        context.coordinator.textView = textView
        
        textView.backgroundColor = .clear
        textView.isScrollEnabled = true
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.textColor = UIColor.label
        
        // Match native notes text container inset
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        textView.textContainer.lineFragmentPadding = 0
        
        let accessoryView = NativeKeyboardToolbar(
            onToggleChecklist: {
                context.coordinator.toggleChecklistAction()
            },
            onDismissKeyboard: { [weak textView] in
                textView?.resignFirstResponder()
            }
        )
        
        let hostingController = UIHostingController(rootView: accessoryView)
        hostingController.view.autoresizingMask = .flexibleWidth
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 320, height: 50)
        hostingController.view.backgroundColor = .clear
        
        textView.inputAccessoryView = hostingController.view
        
        // Tap gesture ONLY for toggling checklists directly when tapped on visual checkbox
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tapGesture.delegate = context.coordinator
        textView.addGestureRecognizer(tapGesture)
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if context.coordinator.lastParsedText != text && !context.coordinator.isUpdating {
            let font = uiView.font ?? UIFont.preferredFont(forTextStyle: .body)
            let attr = NativeTextView.parseToAttributed(text: text, font: font)
            
            let selectedRange = uiView.selectedRange
            uiView.attributedText = attr
            
            let length = uiView.attributedText.length
            if selectedRange.location <= length {
                let maxLen = min(selectedRange.length, length - selectedRange.location)
                uiView.selectedRange = NSRange(location: selectedRange.location, length: maxLen)
            }
            
            context.coordinator.lastParsedText = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    static func parseToAttributed(text: String, font: UIFont) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.headIndent = 32
        paragraphStyle.firstLineHeadIndent = 0
        paragraphStyle.paragraphSpacing = 8
        
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.label,
            .paragraphStyle: NSMutableParagraphStyle() 
        ]
        
        let checklistAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.label,
            .paragraphStyle: paragraphStyle
        ]
        
        let lines = text.components(separatedBy: "\n")
        
        for (index, line) in lines.enumerated() {
            if line.hasPrefix("- [ ] ") {
                let attachment = CheckboxAttachment(isChecked: false)
                let attrString = NSMutableAttributedString(attachment: attachment)
                attrString.append(NSAttributedString(string: " " + String(line.dropFirst(6))))
                attrString.addAttributes(checklistAttributes, range: NSRange(location: 0, length: attrString.length))
                result.append(attrString)
            } else if line.hasPrefix("- [x] ") {
                let attachment = CheckboxAttachment(isChecked: true)
                let attrString = NSMutableAttributedString(attachment: attachment)
                let textStr = " " + String(line.dropFirst(6))
                attrString.append(NSAttributedString(string: textStr))
                attrString.addAttributes(checklistAttributes, range: NSRange(location: 0, length: attrString.length))
                
                let textRange = NSRange(location: 1, length: textStr.utf16.count)
                attrString.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: textRange)
                attrString.addAttribute(.foregroundColor, value: UIColor.secondaryLabel, range: textRange)
                
                result.append(attrString)
            } else {
                result.append(NSAttributedString(string: line, attributes: normalAttributes))
            }
            
            if index < lines.count - 1 {
                let newlineAttrs = line.hasPrefix("- [ ] ") || line.hasPrefix("- [x] ") ? checklistAttributes : normalAttributes
                result.append(NSAttributedString(string: "\n", attributes: newlineAttrs))
            }
        }
        
        return result
    }
    
    static func serializeToString(attributed: NSAttributedString) -> String {
        var result = ""
        let string = attributed.string as NSString
        attributed.enumerateAttributes(in: NSRange(location: 0, length: attributed.length), options: []) { attrs, range, _ in
            if let attachment = attrs[.attachment] as? CheckboxAttachment {
                result += attachment.isChecked ? "- [x]" : "- [ ]"
            } else {
                let substring = string.substring(with: range)
                let cleaned = substring.replacingOccurrences(of: "\u{FFFC}", with: "")
                result += cleaned
            }
        }
        return result
    }
    
    class Coordinator: NSObject, UITextViewDelegate, UIGestureRecognizerDelegate {
        var parent: NativeTextView
        weak var textView: UITextView?
        var lastParsedText: String = ""
        var isUpdating = false
        
        init(_ parent: NativeTextView) {
            self.parent = parent
        }
        
        // MARK: - UIGestureRecognizerDelegate
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            guard let textView = textView else { return false }
            
            let location = touch.location(in: textView)
            let adjustedLocation = CGPoint(x: location.x - textView.textContainerInset.left,
                                           y: location.y - textView.textContainerInset.top)
            
            let layoutManager = textView.layoutManager
            let characterIndex = layoutManager.characterIndex(for: adjustedLocation, in: textView.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
            
            guard characterIndex < textView.textStorage.length else { return false }
            
            let glyphRange = layoutManager.glyphRange(forCharacterRange: NSRange(location: characterIndex, length: 1), actualCharacterRange: nil)
            let boundingRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textView.textContainer)
            
            // Expand tap target to make it more responsive (e.g. 10pt padding in all directions)
            let expandedRect = boundingRect.insetBy(dx: -10, dy: -10)
            
            // Allow gesture to intercept tap ONLY if it hits the checkbox attachment directly
            if expandedRect.contains(adjustedLocation) {
                let attribute = textView.textStorage.attribute(NSAttributedString.Key.attachment, at: characterIndex, effectiveRange: nil)
                if attribute is CheckboxAttachment {
                    return true
                }
            }
            
            return false
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let textView = textView else { return }
            
            let location = gesture.location(in: textView)
            let adjustedLocation = CGPoint(x: location.x - textView.textContainerInset.left,
                                           y: location.y - textView.textContainerInset.top)
            
            let layoutManager = textView.layoutManager
            let characterIndex = layoutManager.characterIndex(for: adjustedLocation, in: textView.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
            
            guard characterIndex < textView.textStorage.length else { return }
            
            let glyphRange = layoutManager.glyphRange(forCharacterRange: NSRange(location: characterIndex, length: 1), actualCharacterRange: nil)
            let boundingRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textView.textContainer)
            
            // Expand tap target to make it more responsive (e.g. 10pt padding in all directions)
            let expandedRect = boundingRect.insetBy(dx: -10, dy: -10)
            
            if expandedRect.contains(adjustedLocation) {
                if let attachment = textView.textStorage.attribute(NSAttributedString.Key.attachment, at: characterIndex, effectiveRange: nil) as? CheckboxAttachment {
                    toggleCheckbox(at: characterIndex, in: textView, currentAttachment: attachment)
                }
            }
        }
        
        private func toggleCheckbox(at index: Int, in textView: UITextView, currentAttachment: CheckboxAttachment) {
            let isChecked = !currentAttachment.isChecked
            let newAttachment = CheckboxAttachment(isChecked: isChecked)
            
            let attrString = NSMutableAttributedString(attributedString: textView.attributedText)
            attrString.removeAttribute(.attachment, range: NSRange(location: index, length: 1))
            attrString.addAttribute(.attachment, value: newAttachment, range: NSRange(location: index, length: 1))
            
            let nsString = attrString.string as NSString
            let lineRange = nsString.lineRange(for: NSRange(location: index, length: 1))
            
            if lineRange.length > 2 {
                let textRange = NSRange(location: index + 2, length: lineRange.length - 2)
                if textRange.location + textRange.length <= attrString.length {
                    if isChecked {
                        attrString.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: textRange)
                        attrString.addAttribute(.foregroundColor, value: UIColor.secondaryLabel, range: textRange)
                    } else {
                        attrString.removeAttribute(.strikethroughStyle, range: textRange)
                        attrString.addAttribute(.foregroundColor, value: UIColor.label, range: textRange)
                    }
                }
            }
            
            isUpdating = true
            let selectedRange = textView.selectedRange
            textView.attributedText = attrString
            textView.selectedRange = selectedRange
            
            let newText = NativeTextView.serializeToString(attributed: attrString)
            self.lastParsedText = newText
            parent.text = newText
            isUpdating = false
            
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
        
        func toggleChecklistAction() {
            guard let textView = textView else { return }
            
            let selectedRange = textView.selectedRange
            let string = textView.textStorage.string as NSString
            
            let lineRange = string.length > 0
                ? string.lineRange(for: NSRange(location: selectedRange.location, length: 0))
                : NSRange(location: 0, length: 0)
            
            if selectedRange.location <= string.length {
                var range = NSRange(location: 0, length: 0)
                let firstCharAttr = lineRange.length > 0
                    ? textView.textStorage.attribute(NSAttributedString.Key.attachment, at: lineRange.location, effectiveRange: &range)
                    : nil
                
                if let currentAttachment = firstCharAttr as? CheckboxAttachment {
                    let isChecked = !currentAttachment.isChecked
                    let newAttachment = CheckboxAttachment(isChecked: isChecked)
                    
                    let attrString = NSMutableAttributedString(attributedString: textView.attributedText)
                    attrString.removeAttribute(.attachment, range: NSRange(location: lineRange.location, length: 1))
                    attrString.addAttribute(.attachment, value: newAttachment, range: NSRange(location: lineRange.location, length: 1))
                    
                    let nsString = attrString.string as NSString
                    let actualLineRange = nsString.lineRange(for: NSRange(location: lineRange.location, length: 1))
                    
                    if actualLineRange.length > 2 {
                        let textRange = NSRange(location: lineRange.location + 2, length: actualLineRange.length - 2)
                        if textRange.location + textRange.length <= attrString.length {
                            if isChecked {
                                attrString.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: textRange)
                                attrString.addAttribute(.foregroundColor, value: UIColor.secondaryLabel, range: textRange)
                            } else {
                                attrString.removeAttribute(.strikethroughStyle, range: textRange)
                                attrString.addAttribute(.foregroundColor, value: UIColor.label, range: textRange)
                            }
                        }
                    }
                    
                    isUpdating = true
                    textView.attributedText = attrString
                    textView.selectedRange = selectedRange
                    
                    let newText = NativeTextView.serializeToString(attributed: attrString)
                    self.lastParsedText = newText
                    parent.text = newText
                    isUpdating = false
                    
                } else {
                    isUpdating = true
                    let mutableAttr = NSMutableAttributedString(attributedString: textView.attributedText)
                    
                    let attachment = CheckboxAttachment(isChecked: false)
                    let newBoxStr = NSMutableAttributedString(attachment: attachment)
                    
                    let font = textView.font ?? UIFont.preferredFont(forTextStyle: .body)
                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.headIndent = 32
                    paragraphStyle.firstLineHeadIndent = 0
                    paragraphStyle.paragraphSpacing = 8
                    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.label, .paragraphStyle: paragraphStyle]
                    
                    newBoxStr.append(NSAttributedString(string: " ", attributes: attrs))
                    newBoxStr.addAttributes(attrs, range: NSRange(location: 0, length: newBoxStr.length))
                    
                    mutableAttr.insert(newBoxStr, at: lineRange.location)
                    
                    let nsString = mutableAttr.string as NSString
                    let newLineRange = nsString.lineRange(for: NSRange(location: lineRange.location, length: 1))
                    if newLineRange.location + newLineRange.length <= mutableAttr.length {
                        mutableAttr.addAttributes(attrs, range: newLineRange)
                    }
                    
                    textView.attributedText = mutableAttr
                    
                    let newText = NativeTextView.serializeToString(attributed: mutableAttr)
                    self.lastParsedText = newText
                    parent.text = newText
                    isUpdating = false
                    
                    textView.selectedRange = NSRange(location: selectedRange.location + newBoxStr.length, length: selectedRange.length)
                }
            }
            
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
        
        func textViewDidChange(_ textView: UITextView) {
            if isUpdating { return }
            let newText = NativeTextView.serializeToString(attributed: textView.attributedText)
            self.lastParsedText = newText
            parent.text = newText
        }
        
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if text == "\n" {
                let string = textView.textStorage.string as NSString
                let lineRange = string.lineRange(for: NSRange(location: range.location, length: 0))
                
                if lineRange.location <= string.length {
                    var r = NSRange(location: 0, length: 0)
                    let firstCharAttr = lineRange.length > 0
                        ? textView.textStorage.attribute(NSAttributedString.Key.attachment, at: lineRange.location, effectiveRange: &r)
                        : nil
                        
                    if firstCharAttr is CheckboxAttachment {
                        let isLineEmpty = lineRange.length <= 2 || (lineRange.length == 3 && string.substring(with: lineRange).hasSuffix("\n"))
                        
                        if isLineEmpty {
                            isUpdating = true
                            let mutableAttr = NSMutableAttributedString(attributedString: textView.attributedText)
                            mutableAttr.replaceCharacters(in: lineRange, with: "")
                            
                            let font = textView.font ?? UIFont.preferredFont(forTextStyle: .body)
                            let normalAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.label, .paragraphStyle: NSMutableParagraphStyle()]
                            if lineRange.location < mutableAttr.length {
                                let nsString = mutableAttr.string as NSString
                                let newRange = nsString.lineRange(for: NSRange(location: lineRange.location, length: 0))
                                mutableAttr.addAttributes(normalAttrs, range: newRange)
                            }
                            
                            textView.attributedText = mutableAttr
                            
                            let newText = NativeTextView.serializeToString(attributed: mutableAttr)
                            self.lastParsedText = newText
                            parent.text = newText
                            isUpdating = false
                            
                            textView.selectedRange = NSRange(location: lineRange.location, length: 0)
                            return false
                        } else {
                            isUpdating = true
                            let mutableAttr = NSMutableAttributedString(attributedString: textView.attributedText)
                            
                            let attachment = CheckboxAttachment(isChecked: false)
                            let newBoxStr = NSMutableAttributedString(string: "\n")
                            newBoxStr.append(NSAttributedString(attachment: attachment))
                            
                            let font = textView.font ?? UIFont.preferredFont(forTextStyle: .body)
                            let paragraphStyle = NSMutableParagraphStyle()
                            paragraphStyle.headIndent = 32
                            paragraphStyle.firstLineHeadIndent = 0
                            paragraphStyle.paragraphSpacing = 8
                            let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.label, .paragraphStyle: paragraphStyle]
                            
                            newBoxStr.append(NSAttributedString(string: " ", attributes: attrs))
                            newBoxStr.addAttributes(attrs, range: NSRange(location: 0, length: newBoxStr.length))
                            
                            mutableAttr.replaceCharacters(in: range, with: newBoxStr)
                            textView.attributedText = mutableAttr
                            
                            let newText = NativeTextView.serializeToString(attributed: mutableAttr)
                            self.lastParsedText = newText
                            parent.text = newText
                            isUpdating = false
                            
                            textView.selectedRange = NSRange(location: range.location + newBoxStr.length, length: 0)
                            return false
                        }
                    }
                }
            }
            return true
        }
    }
}
