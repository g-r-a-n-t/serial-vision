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

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: Storyboard References
    
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    var imagePicker: UIImagePickerController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.resultLabel.text = "Select an image to begin"
        
        self.imagePicker = UIImagePickerController()
        self.imagePicker.delegate = self
    }
    
    // MARK: - Image reader
    
    // Question so you must test for existance
    var image: UIImage? {
        didSet {
            self.imageView.image = image
            print("Run the algorithum to get the serial number")
            print(self.image ?? "No image selected")
            // TODO: - Implement the image reading
            self.resultLabel.text = "Processing..."
            self.resultLabel.textColor = UIColor.yellow
            self.foundSerial = false
            DispatchQueue.global(qos: .background).async {
                let imageReader = ImageReader()
                imageReader.classifyBoundedCharacters(image: self.image!.fixOrientation(), distributionSize: 4, callback: self.classificationsCallback)
            }
        }
    }
    var foundSerial = false
    
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
    
    @IBAction func selectImageClicked(_ sender: Any) {
        print("Image Clicked")
        present(self.imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func tapOnSerialNumber(_ sender: Any) {
        guard self.foundSerial else { return }
        
        // Prepare for the navigation
        // And setup the desired subview correctly
//        self.performSegue(withIdentifier: "Segue", sender: self)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    internal func imagePickerController(_ picker: UIImagePickerController,
                                        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        // Gracefully fail
        self.image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        
        if self.image == nil {
            print("This info marker failed to confrom")
        }
        
        // Dismiss the picker to return to original view controller.
        dismiss(animated: true, completion: nil)
    }
}

