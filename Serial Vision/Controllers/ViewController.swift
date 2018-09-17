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

    // MARK: - Storyboard References
    
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    // Question so you must test for existance
    var image: UIImage? {
        didSet {
            self.imageView.image = image
        }
    }
    
    var imagePicker: UIImagePickerController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.resultLabel.text = "Select an image to begin"
        
        self.imagePicker = UIImagePickerController()
        self.imagePicker.delegate = self
    }

    // MARK: - IBActions
    
    @IBAction func selectImageClicked(_ sender: Any) {
        print("Image Clicked")
        present(self.imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func runAction(_ sender: Any) {
        print("Run the algorithum to get the serial number")
        print(self.image ?? "No image selected")
        // TODO: - Implement the image reading
        let imageReader = ImageReader()
        imageReader.detectText(image: self.image!, returnSize: 4, callback: detectTextCallback)
    }
    
    func detectTextCallback(results: [[String: Double]]) {
        let mockSerials = MockJamfProSerials()
        let realSerials = ["CO2T83GXGTFM", "DLXNR94XG5VJ", "CO2K21PKDRVG", "CO2WN1FFHV2R", "F9FT5J0ZHLF9", "CO2PQDLUG8WP", "CO2TLOUWGTFM"]
        let serials = mockSerials + realSerials
        for result in results {
            print(result)
        }
        let serialFinder = SerialFinder(serialLength: 12, jamfProSerials: serials)
        let potentialSerials = serialFinder.potentialSerials(characterProbabilityDistributions: results)
        print(potentialSerials)
        for serial in potentialSerials.keys {
            resultLabel.text = serial
        }
    }
    
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

