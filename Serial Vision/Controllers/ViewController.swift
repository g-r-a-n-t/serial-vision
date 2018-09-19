//
//  ViewController.swift
//  Serial Vision
//
//  Created by Brandon Roehl on 9/10/18.
//  Copyright © 2018 Jamf. All rights reserved.
//

import UIKit
import Vision
import CoreML
import AVFoundation

class ViewController: UIViewController, UINavigationControllerDelegate {

    // MARK: Storyboard References
    
    @IBOutlet weak var resultLabel: UILabel!
    //@IBOutlet weak var cameraPreviewView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    
    private let imageReader = ImageReader()
    private var foundSerial = false
    private var lastCheck = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let captureSession = CaptureSession(delegate: self, previewView: self.imageView)
        captureSession.startRunning()
    }
    
    fileprivate func classificationsCallback(results: [[String: Double]]) {
        let mockSerials = MockJamfProSerials()
        let realSerials = ["CO2T83GXGTFM", "DLXNR94XG5VJ", "CO2K21PKDRVG", "CO2WN1FFHV2R", "F9FT5J0ZHLF9", "CO2PQDLUG8WP", "CO2TLOUWGTFM"]
        let serials = mockSerials + realSerials
        let serialFinder = SerialFinder(serialLength: 12, jamfProSerials: serials)
        let matchingSerials = serialFinder.matchingSerials(characterProbabilityDistributions: results)
        print(matchingSerials)
        
        if matchingSerials.count > 0 {
            DispatchQueue.main.async {
                self.resultLabel.text = matchingSerials[0].key
                self.resultLabel.textColor = UIColor.green
                self.foundSerial = true
            }
        }
    }

    // MARK: - IBActions
    @IBAction func tapOnSerialNumber(_ sender: Any) {}
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let uiImage = convert(cmage: ciImage)
        
        let time = Int(NSDate().timeIntervalSince1970)
        if !foundSerial &&  time - lastCheck > 2 {
            print("orientation0", uiImage.imageOrientation.rawValue)
            imageReader.classifyBoundedCharacters(image: uiImage.fixOrientation(), distributionSize: 4, callback: classificationsCallback)
            lastCheck = time
        }
    }
    
    func convert(cmage:CIImage) -> UIImage {
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(cmage, from: cmage.extent)!
        let image:UIImage = UIImage.init(cgImage: cgImage, scale: 1, orientation: UIImage.Orientation.right)
        return image
    }
}
