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

class ViewController: UIViewController, UINavigationControllerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {

    // MARK: Storyboard References
    
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    private let imageReader = ImageReader()
    private var findingSerial = false
    private var lastCheck = 0
    let requestService = RequestService()
    var searchResults: [MobileDeviceRecord] = []
    
    private var captureSession: AVCaptureSession?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Load Jamf Pro inventory
//        self.getMobileDeviceRecords()
        
        self.captureSession = AVCaptureSession()
        if UIDevice.current.userInterfaceIdiom == .phone {
            self.captureSession?.sessionPreset = .hd1920x1080
        } else {
            self.captureSession?.sessionPreset = .photo
        }
        
        do {
            guard let device = AVCaptureDevice.default(for: .video) else {
                return
            }
            
            let deviceInput = try AVCaptureDeviceInput(device: device)
            if self.captureSession?.canAddInput(deviceInput) ?? false {
                self.captureSession!.addInput(deviceInput)
            }
            
            try device.lockForConfiguration()
            device.videoZoomFactor = 3.0
            device.unlockForConfiguration()
        } catch {
            print("Failed to create capture device input, error=\(error.localizedDescription)")
            return
        }
        
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCMPixelFormat_32BGRA]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoDataOutputQueue"))
        
        if self.captureSession?.canAddOutput(videoDataOutput) ?? false {
            self.captureSession!.addOutput(videoDataOutput)
        }
        
        let connection = videoDataOutput.connection(with: .video)
        connection?.isEnabled = true
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession!)
        previewLayer.backgroundColor = UIColor.black.cgColor
        previewLayer.videoGravity = .resizeAspect
        
        let rootLayer = self.imageView.layer
        rootLayer.masksToBounds = true
        previewLayer.frame = rootLayer.bounds
        rootLayer.addSublayer(previewLayer)
    }
    
    func getMobileDeviceRecords() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        requestService.getMobileDevices() { results, errorMessage in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            if let results = results {
                self.searchResults = results
                print(results)
            }
            if !errorMessage.isEmpty { print("Search error: " + errorMessage) }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.captureSession?.startRunning()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.captureSession?.stopRunning()
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
            }
        }
        self.findingSerial = false
    }

    // MARK: - IBActions
    @IBAction func tapOnSerialNumber(_ sender: Any) {}
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard !self.findingSerial else {
            return
        }
        findingSerial = true
        DispatchQueue.global(qos: .background).async {
            let uiImage = UIImage(sampleBuffer: sampleBuffer)
            print("orientation0", uiImage!.imageOrientation.rawValue)
            self.imageReader.classifyBoundedCharacters(image: uiImage!.fixOrientation(), distributionSize: 4, callback: self.classificationsCallback)
        }
    }
}
