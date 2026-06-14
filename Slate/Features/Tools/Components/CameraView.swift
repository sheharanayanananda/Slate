//
//  CameraView.swift
//  Slate
//
//  Created by Thineth Shehara on 2026-02-22.
//

import SwiftUI

struct CameraView: UIViewControllerRepresentable {
    @Binding var takePhoto: Bool
    var onPhotoCaptured: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.onPhotoCapture = { image in
            DispatchQueue.main.async {
                takePhoto = false // reset trigger after capture completes
                onPhotoCaptured(image)
            }
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        if takePhoto {
            uiViewController.capturePhoto()
        }
    }
}
