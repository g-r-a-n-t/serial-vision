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
    var model: VNCoreMLModel!
    var textMetadata = [Int: [Int: String]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.resultLabel.text = "Select an image to begin"
        
        self.imagePicker = UIImagePickerController()
        self.imagePicker.delegate = self
        loadModel()
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
        detectText(image: self.image!)
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
    
    // COPIED IN
    
    private func loadModel() {
        model = try? VNCoreMLModel(for: Alphanum_28x28().model)
    }
    
    func detectText(image: UIImage) {
        let convertedImage = image |> adjustColors |> convertToGrayscale
        let handler = VNImageRequestHandler(cgImage: convertedImage.cgImage!)
        let request: VNDetectTextRectanglesRequest =
            VNDetectTextRectanglesRequest(completionHandler: { [unowned self] (request, error) in
                if (error != nil) {
                    print("Got Error In Run Text Dectect Request :(")
                } else {
                    guard let results = request.results as? Array<VNTextObservation> else {
                        fatalError("Unexpected result type from VNDetectTextRectanglesRequest")
                    }
                    if (results.count == 0) {
                        self.handleEmptyResults()
                        return
                    }
                    var numberOfWords = 0
                    for textObservation in results {
                        var numberOfCharacters = 0
                        for rectangleObservation in textObservation.characterBoxes! {
                            let croppedImage = crop(image: image, rectangle: rectangleObservation)
                            if let croppedImage = croppedImage {
                                let processedImage = preProcess(image: croppedImage)
                                self.classifyImage(image: processedImage,
                                                   wordNumber: numberOfWords,
                                                   characterNumber: numberOfCharacters)
                                numberOfCharacters += 1
                            }
                        }
                        numberOfWords += 1
                    }
                }
            })
        request.reportCharacterBoxes = true
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    func handleEmptyResults() {
        DispatchQueue.main.async {
            
        }
        
    }
    
    func classifyImage(image: UIImage, wordNumber: Int, characterNumber: Int) {
        //saveImageToDocumentDirectory(image)
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            guard let results = request.results as? [VNClassificationObservation],
                let topResult = results.first else {
                    fatalError("Unexpected result type from VNCoreMLRequest")
            }
            let result = topResult.identifier
            let classificationInfo: [String: Any] = ["wordNumber" : wordNumber,
                                                     "characterNumber" : characterNumber,
                                                     "class" : result]
            self?.handleResult(classificationInfo)
        }
        guard let ciImage = CIImage(image: image) else {
            fatalError("Could not convert UIImage to CIImage :(")
        }
        let handler = VNImageRequestHandler(ciImage: ciImage)
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try handler.perform([request])
            }
            catch {
                print(error)
            }
        }
    }
    
    func handleResult(_ result: [String: Any]) {
        objc_sync_enter(self)
        guard let wordNumber = result["wordNumber"] as? Int else {
            return
        }
        guard let characterNumber = result["characterNumber"] as? Int else {
            return
        }
        guard let characterClass = result["class"] as? String else {
            return
        }
        if (textMetadata[wordNumber] == nil) {
            let tmp: [Int: String] = [characterNumber: characterClass]
            textMetadata[wordNumber] = tmp
        } else {
            var tmp = textMetadata[wordNumber]!
            tmp[characterNumber] = characterClass
            textMetadata[wordNumber] = tmp
        }
        objc_sync_exit(self)
        DispatchQueue.main.async {
            //self.hideActivityIndicator()
            self.showDetectedText()
        }
    }
    
    func showDetectedText() {
        var result: String = ""
        if (textMetadata.isEmpty) {
            resultLabel.text = "The image does not contain any text."
            return
        }
        let sortedKeys = textMetadata.keys.sorted()
        for sortedKey in sortedKeys {
            result +=  word(fromDictionary: textMetadata[sortedKey]!) + " "
        }
        resultLabel.text = result
    }
    
    func word(fromDictionary dictionary: [Int : String]) -> String {
        let sortedKeys = dictionary.keys.sorted()
        var word: String = ""
        for sortedKey in sortedKeys {
            let char: String = dictionary[sortedKey]!
            word += char
        }
        return word
    }
    
    func saveImageToDocumentDirectory(_ chosenImage: UIImage) -> String {
        let directoryPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].relativePath
        if !FileManager.default.fileExists(atPath: directoryPath) {
            do {
                try FileManager.default.createDirectory(at: NSURL.fileURL(withPath: directoryPath), withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error)
            }
        }
        let filename = "test".appending(".jpg")
        let filepath = directoryPath.appending(filename)
        let url = NSURL.fileURL(withPath: filepath)
        do {
            try chosenImage.jpegData(compressionQuality: 1.0)?.write(to: url, options: .atomic)
            return String.init("/Documents/\(filename)")
            
        } catch {
            print(error)
            print("file cant not be save at path \(filepath), with error : \(error)");
            return filepath
        }
    }
    
}

