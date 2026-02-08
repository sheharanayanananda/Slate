//
//  NoteSharingHelper.swift
//  Notes
//
//  Created by Thineth Shehara on 2026-02-08.
//

import UIKit
import PDFKit

struct NoteSharingHelper {
    
    static func generateRichText(for note: NotesModel) -> NSAttributedString {
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        
        let descAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17)
        ]
        
        let attributedString = NSMutableAttributedString(string: note.title + "\n\n", attributes: titleAttributes)
        attributedString.append(NSAttributedString(string: note.desc, attributes: descAttributes))
        
        return attributedString
    }
    
    static func generatePDF(for note: NotesModel) -> URL? {
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
    
    static func generateTextFile(for note: NotesModel) -> URL? {
        let text = "\(note.title)\n\n\(note.desc)"
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
