import Testing
import UIKit
@testable import Slate

struct SlateTests {

    @Test func testBasicIndentationParsing() throws {
        let font = UIFont.systemFont(ofSize: 16)
        
        // No indent
        let attr1 = NativeTextView.parseToAttributed(text: "Hello", font: font)
        let style1 = attr1.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
        #expect(style1?.firstLineHeadIndent == 0)
        #expect(style1?.headIndent == 0)
        
        // 1 level indent (2 spaces)
        let attr2 = NativeTextView.parseToAttributed(text: "  Hello", font: font)
        let style2 = attr2.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
        #expect(style2?.firstLineHeadIndent == 24)
        #expect(style2?.headIndent == 24)
        
        // 2 levels indent (4 spaces)
        let attr3 = NativeTextView.parseToAttributed(text: "    Hello", font: font)
        let style3 = attr3.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
        #expect(style3?.firstLineHeadIndent == 48)
        #expect(style3?.headIndent == 48)
    }

    @Test func testListIndentationParsing() throws {
        let font = UIFont.systemFont(ofSize: 16)
        
        // Indented checklist
        let attrCheck = NativeTextView.parseToAttributed(text: "  - [ ] Task", font: font)
        let styleCheck = attrCheck.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
        #expect(styleCheck?.firstLineHeadIndent == 24)
        #expect(styleCheck?.headIndent == 56) // 24 + 32
        
        // Indented bullet
        let attrBullet = NativeTextView.parseToAttributed(text: "    - Bullet", font: font)
        let styleBullet = attrBullet.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
        #expect(styleBullet?.firstLineHeadIndent == 48)
        #expect(styleBullet?.headIndent == 64) // 48 + 16
        
        // Indented number
        let attrNum = NativeTextView.parseToAttributed(text: "  1. Number", font: font)
        let styleNum = attrNum.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
        #expect(styleNum?.firstLineHeadIndent == 24)
        #expect(styleNum?.headIndent == 44) // 24 + 20
    }

    @Test func testSerializerRoundtrip() throws {
        let font = UIFont.systemFont(ofSize: 16)
        
        let cases = [
            "Hello",
            "  Hello",
            "    Hello",
            "- [ ] Task",
            "  - [ ] Task",
            "    - [ ] Task",
            "- [x] Done",
            "  - [x] Done",
            "- Bullet",
            "  - Bullet",
            "1. One",
            "  2. Two",
            "**Bold**",
            "*Italic*",
            "<u>Underline</u>",
            "~~Strikethrough~~",
            "  **Bold** and *Italic* with <u>Underline</u> and ~~Strikethrough~~"
        ]
        
        for testCase in cases {
            let attr = NativeTextView.parseToAttributed(text: testCase, font: font)
            let serialized = NativeTextView.serializeToString(attributed: attr)
            #expect(serialized == testCase, "Failed for case: '\(testCase)' (got '\(serialized)')")
        }
    }

    @Test func testMarkdownHeaders() throws {
        let text = "# Header 1\n## Header 2\n### Header 3\n#NotHeader"
        let blocks = SlateMarkdownParser.parse(text)
        
        #expect(blocks.count == 4)
        
        if case .heading(let level, let content) = blocks[0] {
            #expect(level == 1)
            #expect(content == "Header 1")
        } else {
            #expect(Bool(false), "Expected Header 1 block")
        }
        
        if case .heading(let level, let content) = blocks[1] {
            #expect(level == 2)
            #expect(content == "Header 2")
        } else {
            #expect(Bool(false), "Expected Header 2 block")
        }
        
        if case .paragraph(let content) = blocks[3] {
            #expect(content == "#NotHeader")
        } else {
            #expect(Bool(false), "Expected paragraph for #NotHeader")
        }
    }

    @Test func testHeadingParsingAndSerialization() throws {
        let font = UIFont.preferredFont(forTextStyle: .body)
        let headingMarkdown = "### 1. For a point mass (Linear)"
        let attr = NativeTextView.parseToAttributed(text: headingMarkdown, font: font)
        
        // Ensure visual text does NOT contain ###
        #expect(!attr.string.contains("###"))
        #expect(attr.string.contains("1. For a point mass (Linear)"))
        
        // Ensure level attribute is present
        let level = attr.attribute(.slateHeadingLevel, at: 0, effectiveRange: nil) as? Int
        #expect(level == 3)
        
        // Ensure serialized text restores ### without unwanted asterisks
        let serialized = NativeTextView.serializeToString(attributed: attr)
        #expect(serialized == headingMarkdown)
    }

    @Test func testInlineMathAndGreekParsing() throws {
        let font = UIFont.preferredFont(forTextStyle: .body)
        let mathMarkdown = "- $L$: Angular momentum\n- $\\theta$: Angle between the radius and velocity vectors"
        let attr = NativeTextView.parseToAttributed(text: mathMarkdown, font: font)
        
        // Visually should contain Greek glyph and not raw LaTeX or dollar signs
        #expect(attr.string.contains("θ"))
        #expect(!attr.string.contains("$\\theta$"))
        #expect(!attr.string.contains("$L$"))
        
        // Serialization should faithfully restore $L$ and $\theta$
        let serialized = NativeTextView.serializeToString(attributed: attr)
        #expect(serialized.contains("$L$: Angular momentum"))
        #expect(serialized.contains("$\\theta$: Angle between the radius and velocity vectors"))
    }

    @Test func testInlineCodeParsing() throws {
        let font = UIFont.preferredFont(forTextStyle: .body)
        let codeMarkdown = "Use `let x = 10` in Swift"
        let attr = NativeTextView.parseToAttributed(text: codeMarkdown, font: font)
        
        #expect(attr.string == "Use let x = 10 in Swift")
        let serialized = NativeTextView.serializeToString(attributed: attr)
        #expect(serialized == codeMarkdown)
    }

    @Test @MainActor func testSlateTextViewRendering() throws {
        let noteText = """
        # My Note
        Here is some text with **bold** and *italic*.
        - [ ] First task
        - [x] Second task
        - Bullet point
        1. Numbered item
        """
        let blocks = NoteBlockUtility.splitIntoBlockItems(noteText)
        #expect(!blocks.isEmpty)
        for item in blocks {
            if !item.isSpecial {
                let textView = SlateTextView()
                let font = UIFont.preferredFont(forTextStyle: .body)
                let attr = NativeTextView.parseToAttributed(text: item.rawText, font: font)
                textView.attributedText = attr
                
                let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
                window.addSubview(textView)
                textView.frame = CGRect(x: 0, y: 0, width: 375, height: 100)
                textView.setNeedsLayout()
                textView.layoutIfNeeded()
                
                let size = textView.sizeThatFits(CGSize(width: 375, height: CGFloat.greatestFiniteMagnitude))
                #expect(size.height > 0)
            }
        }
    }

    @Test func testCheckedChecklistStrikethroughAndSpacing() throws {
        let font = UIFont.preferredFont(forTextStyle: .body)
        let checklistMarkdown = "- [x] Test markdown rendering\n- [ ] Review formatting guidelines"
        let attr = NativeTextView.parseToAttributed(text: checklistMarkdown, font: font)
        
        // Find the index of the leading space right after the attachment in line 1
        // Attachment is at index 0 (\u{FFFC}), space is at index 1
        #expect(attr.length > 2)
        let spaceChar = (attr.string as NSString).substring(with: NSRange(location: 1, length: 1))
        #expect(spaceChar == " ")
        
        // The space must NOT have strikethroughStyle applied
        let spaceStrikethrough = attr.attribute(.strikethroughStyle, at: 1, effectiveRange: nil) as? Int
        #expect(spaceStrikethrough == nil || spaceStrikethrough == 0)
        
        // The actual text "Test" must have strikethroughStyle applied
        let textStrikethrough = attr.attribute(.strikethroughStyle, at: 2, effectiveRange: nil) as? Int
        #expect(textStrikethrough == NSUnderlineStyle.single.rawValue)
        
        // Serialization must roundtrip accurately
        let serialized = NativeTextView.serializeToString(attributed: attr)
        #expect(serialized == checklistMarkdown)
    }
}

