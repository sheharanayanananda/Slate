//
//  NoteSharingHelper.swift
//  Slate
//
//  Created by Thineth Shehara on 2026-02-08.
//

import UIKit
import PDFKit

struct NoteSharingHelper {
    
    static func generateRichText(for note: SlateModel) -> NSAttributedString {
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold)
        ]
        
        let attributedString = NSMutableAttributedString(string: note.title + "\n\n", attributes: titleAttributes)
        
        // Append the actual parsed rich text
        attributedString.append(note.attributedDesc)
        
        return attributedString
    }
    
    static func generateMarkdownText(for note: SlateModel) -> String {
        return "*\(note.title)*\n\n\(note.previewText)"
    }
    
    static func generatePDF(for note: SlateModel) -> URL? {
        let content = generateRichText(for: note)
        
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792)) // Standard US Letter size
        
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(note.title).pdf")
        
        do {
            try pdfRenderer.writePDF(to: fileURL) { context in
                context.beginPage()
                
                content.draw(in: CGRect(x: 20, y: 20, width: 572, height: 752))
            }
            return fileURL
        } catch {
            print("Could not create PDF file: \(error)")
            return nil
        }
    }
    
    static func generateTextFile(for note: SlateModel) -> URL? {
        let text = "\(note.title)\n\n\(note.previewText)"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(note.title).txt")
        
        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Could not create text file: \(error)")
            return nil
        }
    }
}

class NoteItemSource: NSObject, UIActivityItemSource {
    let note: SlateModel
    
    init(note: SlateModel) {
        self.note = note
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return note.title
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        if activityType == .message || activityType == .mail || activityType?.rawValue == "com.apple.mobilenotes.SharingExtension" {
            let richText = NoteSharingHelper.generateRichText(for: note)
            if let rtfData = try? richText.data(from: NSRange(location: 0, length: richText.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]) {
                return rtfData
            }
            return richText
        } else {
            return NoteSharingHelper.generateMarkdownText(for: note)
        }
    }
}
