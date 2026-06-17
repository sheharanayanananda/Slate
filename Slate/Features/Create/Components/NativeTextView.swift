//
//  NativeTextView.swift
//  Slate
//

import SwiftUI
import UIKit

struct NativeTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var rtfData: Data?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.isScrollEnabled = true
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.textColor = UIColor.label
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        textView.textContainer.lineFragmentPadding = 0
        textView.allowsEditingTextAttributes = true // Enable rich text editing natively
        
        // Setup Keyboard Accessory Toolbar
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        toolbar.isTranslucent = true
        
        let boldBtn = UIBarButtonItem(image: UIImage(systemName: "bold"), style: .plain, target: context.coordinator, action: #selector(Coordinator.toggleBold))
        let italicBtn = UIBarButtonItem(image: UIImage(systemName: "italic"), style: .plain, target: context.coordinator, action: #selector(Coordinator.toggleItalic))
        let strikeBtn = UIBarButtonItem(image: UIImage(systemName: "strikethrough"), style: .plain, target: context.coordinator, action: #selector(Coordinator.toggleStrikethrough))
        
        let checklistBtn = UIBarButtonItem(image: UIImage(systemName: "checklist"), style: .plain, target: context.coordinator, action: #selector(Coordinator.toggleChecklist))
        let bulletBtn = UIBarButtonItem(image: UIImage(systemName: "list.bullet"), style: .plain, target: context.coordinator, action: #selector(Coordinator.toggleBulletList))
        let numBtn = UIBarButtonItem(image: UIImage(systemName: "list.number"), style: .plain, target: context.coordinator, action: #selector(Coordinator.toggleNumberList))
        
        let dismissBtn = UIBarButtonItem(image: UIImage(systemName: "keyboard.chevron.compact.down"), style: .plain, target: context.coordinator, action: #selector(Coordinator.dismissKeyboard))
        
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let space = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        space.width = 16
        
        toolbar.items = [boldBtn, italicBtn, strikeBtn, space, checklistBtn, bulletBtn, numBtn, flex, dismissBtn]
        toolbar.tintColor = UIColor.label
        
        let accessoryView = KeyboardAccessoryView(toolbar: toolbar)
        textView.inputAccessoryView = accessoryView
        context.coordinator.textView = textView
        
        // Tap gesture for checklists
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tap.delegate = context.coordinator
        textView.addGestureRecognizer(tap)
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if !context.coordinator.isUpdating {
            if let data = rtfData, let attr = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.rtfd], documentAttributes: nil) {
                if uiView.attributedText != attr {
                    uiView.attributedText = attr
                }
            } else if uiView.text != text {
                let parsedAttr = NativeTextView.convertMarkdownToNative(text)
                uiView.attributedText = parsedAttr
                
                // Immediately save back the parsed RTF data to the model
                DispatchQueue.main.async {
                    context.coordinator.updateParent(uiView)
                }
            }
        }
    }
    
    static func convertMarkdownToNative(_ markdown: String) -> NSAttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        let attrString: NSMutableAttributedString
        if let attrStr = try? AttributedString(markdown: markdown, options: options) {
            attrString = NSMutableAttributedString(attrStr)
        } else {
            attrString = NSMutableAttributedString(string: markdown)
        }
        
        let defaultFont = UIFont.preferredFont(forTextStyle: .body)
        let totalRange = NSRange(location: 0, length: attrString.length)
        
        // Preserve any parsed fonts from AttributedString, but ensure everything has at least body font
        attrString.enumerateAttribute(.font, in: totalRange, options: []) { value, range, _ in
            if value == nil {
                attrString.addAttribute(.font, value: defaultFont, range: range)
            }
        }
        
        attrString.addAttribute(.foregroundColor, value: UIColor.label, range: totalRange)
        
        // Convert Markdown checklists into NSTextAttachment checkboxes
        if let regex = try? NSRegularExpression(pattern: "^- \\[([ xX])\\] ", options: [.anchorsMatchLines]) {
            let matches = regex.matches(in: attrString.string, options: [], range: NSRange(location: 0, length: attrString.length))
            for match in matches.reversed() {
                let rangeInString = Range(match.range(at: 1), in: attrString.string)!
                let checkStr = String(attrString.string[rangeInString])
                let isChecked = (checkStr == "x" || checkStr == "X")
                
                let attachment = NSTextAttachment()
                let imageName = isChecked ? "checkmark.circle.fill" : "circle"
                let tintColor = isChecked ? UIColor.systemBlue : UIColor.label
                attachment.image = UIImage(systemName: imageName)?.withTintColor(tintColor, renderingMode: .alwaysOriginal)
                attachment.bounds = CGRect(x: 0, y: -4, width: 20, height: 20)
                
                let newAttr = NSMutableAttributedString(attachment: attachment)
                newAttr.append(NSAttributedString(string: " "))
                newAttr.addAttribute(.font, value: defaultFont, range: NSRange(location: 0, length: newAttr.length))
                newAttr.addAttribute(.customChecklist, value: isChecked, range: NSRange(location: 0, length: 1))
                if isChecked {
                    newAttr.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: 1))
                }
                
                attrString.replaceCharacters(in: match.range, with: newAttr)
                
                // If checked, strikethrough the rest of the line
                if isChecked {
                    let nsString = attrString.string as NSString
                    let lineRange = nsString.lineRange(for: NSRange(location: match.range.location, length: 0))
                    let textRange = NSRange(location: match.range.location + 2, length: lineRange.length - 2 - (match.range.location - lineRange.location))
                    if textRange.length > 0 {
                        attrString.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: textRange)
                        attrString.addAttribute(.foregroundColor, value: UIColor.secondaryLabel, range: textRange)
                    }
                }
            }
        }
        
        return attrString
    }
    
    static func convertNativeToMarkdown(_ attrString: NSAttributedString) -> String {
        let mutableStr = NSMutableString(string: attrString.string)
        var offset = 0
        
        attrString.enumerateAttribute(.customChecklist, in: NSRange(location: 0, length: attrString.length), options: []) { value, range, _ in
            if let isChecked = value as? Bool {
                let replacement = isChecked ? "- [x] " : "- [ ] "
                let actualLocation = range.location + offset
                
                var lengthToRemove = 1
                if actualLocation + 1 < mutableStr.length {
                    let nextChar = mutableStr.substring(with: NSRange(location: actualLocation + 1, length: 1))
                    if nextChar == " " {
                        lengthToRemove = 2
                    }
                }
                
                let targetRange = NSRange(location: actualLocation, length: lengthToRemove)
                mutableStr.replaceCharacters(in: targetRange, with: replacement)
                offset += (replacement.count - lengthToRemove)
            }
        }
        
        return mutableStr as String
    }
    
    class Coordinator: NSObject, UITextViewDelegate, UIGestureRecognizerDelegate {
        var parent: NativeTextView
        weak var textView: UITextView?
        var isUpdating = false
        
        init(_ parent: NativeTextView) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            updateParent(textView)
        }
        
        func updateParent(_ textView: UITextView) {
            isUpdating = true
            parent.text = NativeTextView.convertNativeToMarkdown(textView.attributedText)
            if let data = try? textView.attributedText.data(from: NSRange(location: 0, length: textView.attributedText.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtfd]) {
                parent.rtfData = data
            }
            isUpdating = false
        }
        
        @objc func toggleBold() {
            guard let tv = textView else { return }
            toggleTrait(trait: .traitBold, in: tv)
        }
        
        @objc func toggleItalic() {
            guard let tv = textView else { return }
            toggleTrait(trait: .traitItalic, in: tv)
        }
        
        @objc func toggleStrikethrough() {
            guard let tv = textView else { return }
            let range = tv.selectedRange
            let attr = tv.textStorage.attributes(at: max(0, range.location - 1), effectiveRange: nil)
            let hasStrike = attr[.strikethroughStyle] != nil
            
            if range.length > 0 {
                if hasStrike {
                    tv.textStorage.removeAttribute(.strikethroughStyle, range: range)
                } else {
                    tv.textStorage.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: range)
                }
            } else {
                var typingAttr = tv.typingAttributes
                if hasStrike {
                    typingAttr.removeValue(forKey: .strikethroughStyle)
                } else {
                    typingAttr[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
                }
                tv.typingAttributes = typingAttr
            }
            updateParent(tv)
        }
        
        private func toggleTrait(trait: UIFontDescriptor.SymbolicTraits, in tv: UITextView) {
            let range = tv.selectedRange
            
            if range.length > 0 {
                tv.textStorage.beginEditing()
                tv.textStorage.enumerateAttribute(.font, in: range, options: []) { value, subrange, _ in
                    guard let font = value as? UIFont else { return }
                    var symTraits = font.fontDescriptor.symbolicTraits
                    if symTraits.contains(trait) {
                        symTraits.remove(trait)
                    } else {
                        symTraits.insert(trait)
                    }
                    if let desc = font.fontDescriptor.withSymbolicTraits(symTraits) {
                        let newFont = UIFont(descriptor: desc, size: font.pointSize)
                        tv.textStorage.addAttribute(.font, value: newFont, range: subrange)
                    }
                }
                tv.textStorage.endEditing()
            } else {
                guard let font = tv.typingAttributes[.font] as? UIFont ?? tv.font else { return }
                var symTraits = font.fontDescriptor.symbolicTraits
                if symTraits.contains(trait) {
                    symTraits.remove(trait)
                } else {
                    symTraits.insert(trait)
                }
                if let desc = font.fontDescriptor.withSymbolicTraits(symTraits) {
                    let newFont = UIFont(descriptor: desc, size: font.pointSize)
                    tv.typingAttributes[.font] = newFont
                }
            }
            updateParent(tv)
        }
        
        @objc func toggleChecklist() {
            guard let tv = textView else { return }
            let range = tv.selectedRange
            let nsString = tv.text as NSString
            let lineRange = nsString.lineRange(for: range)
            
            let attachment = NSTextAttachment()
            attachment.image = UIImage(systemName: "circle")?.withTintColor(.label, renderingMode: .alwaysOriginal)
            attachment.bounds = CGRect(x: 0, y: -4, width: 20, height: 20)
            
            let attrString = NSMutableAttributedString(attachment: attachment)
            attrString.append(NSAttributedString(string: " "))
            // add font attribute to match text
            attrString.addAttribute(.font, value: UIFont.preferredFont(forTextStyle: .body), range: NSRange(location: 0, length: attrString.length))
            attrString.addAttribute(.customChecklist, value: false, range: NSRange(location: 0, length: 1))
            
            tv.textStorage.insert(attrString, at: lineRange.location)
            tv.selectedRange = NSRange(location: range.location + 2, length: range.length)
            updateParent(tv)
        }
        
        @objc func toggleBulletList() {
            toggleList(marker: "• ")
        }
        
        @objc func toggleNumberList() {
            toggleList(marker: "1. ")
        }
        
        private func toggleList(marker: String) {
            guard let tv = textView else { return }
            let range = tv.selectedRange
            let nsString = tv.text as NSString
            let lineRange = nsString.lineRange(for: range)
            
            let attrString = NSAttributedString(string: marker, attributes: [.font: UIFont.preferredFont(forTextStyle: .body)])
            tv.textStorage.insert(attrString, at: lineRange.location)
            tv.selectedRange = NSRange(location: range.location + marker.count, length: range.length)
            updateParent(tv)
        }
        
        @objc func dismissKeyboard() {
            textView?.resignFirstResponder()
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let tv = textView else { return }
            var location = gesture.location(in: tv)
            location.x -= tv.textContainerInset.left
            location.y -= tv.textContainerInset.top
            
            let characterIndex = tv.layoutManager.characterIndex(for: location, in: tv.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
            guard characterIndex < tv.textStorage.length else { return }
            
            if let isChecked = tv.textStorage.attribute(.customChecklist, at: characterIndex, effectiveRange: nil) as? Bool {
                let newState = !isChecked
                let attachment = NSTextAttachment()
                let imageName = newState ? "checkmark.circle.fill" : "circle"
                let tintColor = newState ? UIColor.systemBlue : UIColor.label
                attachment.image = UIImage(systemName: imageName)?.withTintColor(tintColor, renderingMode: .alwaysOriginal)
                attachment.bounds = CGRect(x: 0, y: -4, width: 20, height: 20)
                
                let newAttr = NSMutableAttributedString(attachment: attachment)
                newAttr.addAttribute(.customChecklist, value: newState, range: NSRange(location: 0, length: 1))
                if newState {
                    newAttr.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: 1))
                }
                
                tv.textStorage.replaceCharacters(in: NSRange(location: characterIndex, length: 1), with: newAttr)
                
                // Strike through the rest of the line if checked
                let lineRange = (tv.text as NSString).lineRange(for: NSRange(location: characterIndex, length: 0))
                let textRange = NSRange(location: characterIndex + 1, length: lineRange.length - 1 - (characterIndex - lineRange.location))
                if textRange.length > 0 {
                    if newState {
                        tv.textStorage.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: textRange)
                        tv.textStorage.addAttribute(.foregroundColor, value: UIColor.secondaryLabel, range: textRange)
                    } else {
                        tv.textStorage.removeAttribute(.strikethroughStyle, range: textRange)
                        tv.textStorage.addAttribute(.foregroundColor, value: UIColor.label, range: textRange)
                    }
                }
                
                updateParent(tv)
            }
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            guard let tv = textView else { return false }
            var location = touch.location(in: tv)
            location.x -= tv.textContainerInset.left
            location.y -= tv.textContainerInset.top
            
            let characterIndex = tv.layoutManager.characterIndex(for: location, in: tv.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
            guard characterIndex < tv.textStorage.length else { return false }
            
            return tv.textStorage.attribute(.customChecklist, at: characterIndex, effectiveRange: nil) != nil
        }
    }
}

extension NSAttributedString.Key {
    static let customChecklist = NSAttributedString.Key("customChecklist")
}

class KeyboardAccessoryView: UIView {
    let toolbar: UIToolbar
    
    init(toolbar: UIToolbar) {
        self.toolbar = toolbar
        super.init(frame: CGRect(x: 0, y: 0, width: 320, height: 56))
        
        backgroundColor = .clear
        addSubview(toolbar)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: self.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -12)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 56)
    }
}
