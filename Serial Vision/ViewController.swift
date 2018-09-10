//
//  ViewController.swift
//  Serial Vision
//
//  Created by Brandon Roehl on 9/10/18.
//  Copyright © 2018 Jamf. All rights reserved.
//

import UIKit

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

