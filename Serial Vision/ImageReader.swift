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

class ImageReader {
    var model: VNCoreMLModel!
    var classificationResults: [[String: Double]]
    
    init() {
        model = try? VNCoreMLModel(for: Alphanum_28x28().model)
        classificationResults = [[:]]
    }
    
    func detectText(image: UIImage, returnSize: Int, callback: @escaping (_: [[String: Double]]) -> ()) {
        let convertedImage = image |> adjustColors |> convertToGrayscale
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
                for textObservation in results {
                    for rectangleObservation in textObservation.characterBoxes! {
                        let croppedImage = crop(image: image, rectangle: rectangleObservation)
                        if let croppedImage = croppedImage {
                            let processedImage = preProcess(image: croppedImage)
                            self.classifyImage(image: processedImage, returnSize: returnSize)
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
    
    private func classifyImage(image: UIImage, returnSize: Int) {
        let request = VNCoreMLRequest(model: model) { request, error in
            let results = request.results as! [VNClassificationObservation]
            var newEntry = [String: Double]()
            for index in 0..<returnSize {
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
