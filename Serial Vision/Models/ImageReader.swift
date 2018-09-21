//
//  ImageReader.swift
//  Serial Vision
//
//  Created by Grant Wuerker on 9/13/18.
//  Copyright © 2018 Jamf. All rights reserved.
//

import Foundation
import UIKit
import Vision
import CoreML

// Public private modifiers on this class cause it could be an exported type
class ImageReader {
    private var model: VNCoreMLModel!
    private var classificationResults: [[String: Double]]
    
    init() {
        model = try? VNCoreMLModel(for: OCR().model)
        classificationResults = [[:]]
    }
    
    public func classifyBoundedCharacters(image: UIImage, distributionSize: Int, callback: @escaping ([[String: Double]]) -> ()) {
        print("image detection", NSDate().timeIntervalSince1970)
        let convertedImage = image.convertToGrayscale()
        print("orientation1", image.imageOrientation.rawValue)
        
        //SaveImage(name: "convertedImage", image: convertedImage)
        
        let handler = VNImageRequestHandler(cgImage: convertedImage.cgImage!)
        let request: VNDetectTextRectanglesRequest = VNDetectTextRectanglesRequest(completionHandler: { [unowned self] (request, error) in
            if (error != nil) {
                print("error in rectangles request")
            } else {
                guard let results = request.results as? Array<VNTextObservation> else {
                    fatalError("Unexpected result type from VNDetectTextRectanglesRequest")
                }
                if (results.count == 0) {
                    print("empty results")
                }
                var imageNumber = 0
//                let prefix = RandomString(length: 4)
                for textObservation in results {
                    for rectangleObservation in textObservation.characterBoxes! {
                        let croppedImage = convertedImage.crop(rectangle: rectangleObservation)
                        if let croppedImage = croppedImage {
                            let processedImage = croppedImage.preProcess()
                            //SaveImage(name: prefix + "-" + String(imageNumber), image: processedImage)
                            self.classifyImage(image: processedImage, distributionSize: distributionSize)
                            imageNumber+=1
                        }
                    }
                }
                
                callback(self.classificationResults)
            }
        })
        
        request.reportCharacterBoxes = true
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    private func classifyImage(image: UIImage, distributionSize: Int) {
        print("image classification", NSDate().timeIntervalSince1970)
        let request = VNCoreMLRequest(model: model) { request, error in
            let results = request.results as! [VNClassificationObservation]
            var newEntry = [String: Double]()
            for index in 0..<distributionSize {
                newEntry[results[index].identifier] = Double(results[index].confidence)
            }
            self.classificationResults.append(newEntry)
        }
        
        guard let ciImage = CIImage(image: image) else {
            fatalError("Could not convert UIImage to CIImage :(")
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage)
        do {
            try handler.perform([request])
        }
        catch {
            print(error)
        }
    }
}
