import Foundation
import UIKit
import AVFoundation

struct CaptureSession {
    private var captureSession: AVCaptureSession
    
    func startRunning() {
        captureSession.startRunning()
    }
    
    init(delegate: AVCaptureVideoDataOutputSampleBufferDelegate, previewView: UIView) {
        captureSession = AVCaptureSession()
        if UIDevice.current.userInterfaceIdiom == .phone {
            captureSession.sessionPreset = .hd1280x720
        } else {
            captureSession.sessionPreset = .photo
        }
        
        do {
            guard let device = AVCaptureDevice.default(for: .video) else {
                return
            }
            
            let deviceInput = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(deviceInput) {
                captureSession.addInput(deviceInput)
            }
        } catch {
            print("Failed to create capture device input, error=\(error.localizedDescription)")
            return
        }
        
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCMPixelFormat_32BGRA]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(delegate, queue: DispatchQueue(label: "VideoDataOutputQueue"))
        
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        }
        
        let connection = videoDataOutput.connection(with: .video)
        connection?.isEnabled = true
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.backgroundColor = UIColor.black.cgColor
        previewLayer.videoGravity = .resizeAspect
        
        let rootLayer = previewView.layer
        rootLayer.masksToBounds = true
        previewLayer.frame = rootLayer.bounds
        rootLayer.addSublayer(previewLayer)
    }
}
