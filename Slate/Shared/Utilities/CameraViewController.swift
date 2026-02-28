//
//  CameraViewController.swift
//  Slate
//
//  Created by Thineth Shehara on 2026-02-22.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {
    var onPhotoCapture: ((UIImage?) -> Void)?
    
    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private let photoOutput = AVCapturePhotoOutput()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Start camera setup
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
        guard let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
        captureSession.beginConfiguration()
        if captureSession.canSetSessionPreset(.hd1920x1080) {
            captureSession.sessionPreset = .hd1920x1080
        }
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }

        // Find the format that is at least 1920x1080 and supports 60fps
        let bestFormat = videoDevice.formats
            .filter { format in
                let dims = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                let supports60fps = format.videoSupportedFrameRateRanges.contains { $0.maxFrameRate >= 60 }
                return dims.width >= 1920 && dims.height >= 1080 && supports60fps
            }
            .sorted {
                let d1 = CMVideoFormatDescriptionGetDimensions($0.formatDescription)
                let d2 = CMVideoFormatDescriptionGetDimensions($1.formatDescription)
                // Sort by descending pixel count
                return d1.width * d1.height > d2.width * d2.height
            }
            .first

        if let format = bestFormat {
            do {
                try videoDevice.lockForConfiguration()
                videoDevice.activeFormat = format
                videoDevice.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 60)
                videoDevice.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 60)
                videoDevice.unlockForConfiguration()
            } catch {
                // handle error
            }
        } else {
            print("No 60fps 1080p format available")
        }
        captureSession.commitConfiguration()

        // Add preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)

        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
    }
    
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let image = photo.fileDataRepresentation().flatMap { UIImage(data: $0) }
        onPhotoCapture?(image)
    }
}
