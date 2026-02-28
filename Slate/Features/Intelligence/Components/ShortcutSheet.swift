//
//  ShortcutSheet.swift
//  Slate
//

import SwiftUI

enum ShortcutType: Identifiable {
    case imageToNote
    case transcript
    case summerize
    
    var id: Self { self }
}

struct ShortcutSheet: View {
    let type: ShortcutType
    
    @State private var capturedImage: UIImage? = nil
    @State private var takePhoto = false
    @State private var presentationDetent: PresentationDetent = .medium
    
    var body: some View {
        NavigationStack {
            Group {
                switch type {
                case .imageToNote:
                    ZStack {
                        if let image = capturedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipped()
                                .ignoresSafeArea()
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarLeading) {
                                        Button(role: .cancel, action: {
                                            capturedImage = nil
                                            presentationDetent = .medium
                                        })
//                                        Button("Retake") {
//                                            capturedImage = nil
//                                            presentationDetent = .medium
//                                        }
                                    }
                                    ToolbarItem(placement: .navigationBarTrailing) {
                                        Button("Process") {
                                            if let image = capturedImage, let base64String = imageToBase64(image) {
                                                createAINote(with: base64String)
                                            }
                                        }
                                        .buttonStyle(.glassProminent)
                                        .tint(.accentColor)
                                    }
                                }
                                .toolbarBackground(.hidden, for: .navigationBar)
                        } else {
                            CameraView(takePhoto: $takePhoto) { image in
                                if let image = image {
                                    capturedImage = image
                                    presentationDetent = .large
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .ignoresSafeArea()
                            
                            VStack {
                                Spacer()
                                Button(action: {
                                    takePhoto = true
                                }) {
                                    Circle()
                                        .fill(Color.white.opacity(0.5))
                                        .frame(width: 80, height: 80)
                                        .shadow(radius: 5)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: 5)
                                        )
                                }
                                .padding(.bottom, 30)
                            }
                            .toolbar(.hidden, for: .navigationBar)
                        }
                    }
                case .transcript:
                    VStack(spacing: 16) {
                        Text("Transcript")
                            .font(.title2)
                            .bold()
                        Text("Coming Soon…")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                case .summerize:
                    VStack(spacing: 16) {
                        Text("Summerize")
                            .font(.title2)
                            .bold()
                        Text("Coming Soon…")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.medium, .large], selection: $presentationDetent)
        }
    }
    
    func imageToBase64(_ image: UIImage) -> String? {
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            return imageData.base64EncodedString()
        }
        return nil
    }
    
    func createAINote(with base64String: String) {
        
    }
}

#Preview {
    ShortcutSheet(type: .imageToNote)
}
