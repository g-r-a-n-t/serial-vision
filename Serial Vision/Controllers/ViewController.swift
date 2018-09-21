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
    
    @IBOutlet weak var resultLabel: SerialCodeView!
    @IBOutlet weak var imageView: UIImageView!
    
    private let imageReader = ImageReader()
    private var findingSerial = false
    private var foundSerial = false
    let requestService = RequestService()
    
    var serialNumber: String? {
        didSet {
            self.resultLabel.text = self.serialNumber
            // If we've seen this serial number update the history else create one
            if let history = CoreHistory.get(serial: self.serialNumber!) {
                history.date = Date() as NSDate
            } else {
                _ = CoreHistory(serialNumber: self.serialNumber!)
            }
        }
    }
    
    private var captureSession: AVCaptureSession?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.resultLabel.text = "Hold Camera to Serial #"
        self.resultLabel.textColor = UIColor.lightGray
    
        self.getJamfInventory()
        
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
            device.videoZoomFactor = 4.0
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
    
    func getJamfInventory() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        requestService.getComputerRecords() { results, errorMessage in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            
            if results != nil { print(results!) }
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
        let serials = CoreComputer.getAll().map({$0.serialNumber})
        let serialFinder = SerialFinder(serialLength: 12, jamfProSerials: serials)
        let matchingSerials = serialFinder.matchingSerials(characterProbabilityDistributions: results)
        print(matchingSerials)
        
        if matchingSerials.count > 0 {
            DispatchQueue.main.async {
                self.serialNumber = matchingSerials[0].key
                self.resultLabel.textColor = .green
                self.foundSerial = true
            }
        }
        self.findingSerial = false
    }

    // MARK: - IBActions
    @IBAction func tapOnSerialNumber(_ sender: Any) {
        if self.serialNumber != nil {
            self.performSegue(withIdentifier: "foundSerialSegue", sender: self)
        }
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard !self.findingSerial && !self.foundSerial else {
            return
        }
        findingSerial = true
        DispatchQueue.global(qos: .background).async {
            let uiImage = UIImage(sampleBuffer: sampleBuffer)
            self.imageReader.classifyBoundedCharacters(image: uiImage!.fixOrientation(), distributionSize: 4, callback: self.classificationsCallback)
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let navController = segue.destination as? UINavigationController, segue.identifier == "foundSerialSegue" {
            // Nested so we can get it to run in a different order for shortcircuting
            if let controller = navController.topViewController as? ComputerInfoViewController {
                controller.serialNumber = self.serialNumber
                controller.allowDismiss()
            }
        }
    }
}
