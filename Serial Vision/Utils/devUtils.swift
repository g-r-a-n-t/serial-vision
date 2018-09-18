//
//  devUtils.swift
//  Serial Vision
//
//  Created by Grant Wuerker on 9/14/18.
//  Copyright © 2018 Jamf. All rights reserved.
//

import Foundation
import UIKit

func SaveImage(name: String, image: UIImage) {
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    // choose a name for your image
    let fileName = name + ".png"
    // create the destination file url to save your image
    let fileURL = documentsDirectory.appendingPathComponent(fileName)
    // get your UIImage jpeg data representation and check if the destination file url already exists
    if let data = image.pngData() {
        do {
            // writes the image data to disk
            try data.write(to: fileURL)
            print("file saved to: " + fileURL.absoluteString)
        } catch {
            print("error saving file:", error)
        }
    }
}

func MockJamfProSerials() -> [String] {
    if let filepath = Bundle.main.path(forResource: "mobile-device-serials", ofType: "txt") {
        do {
            let contents = try String(contentsOfFile: filepath)
            let substrings = contents.split(separator: "\n")
            var strings = [String]()
            for substring in substrings {
                strings.append(String(substring))
            }
            return strings
        } catch {
            // contents could not be loaded
        }
    } else {
        // example.txt not found!
    }
    
    return []
}

func RandomString(length: Int) -> String {
    
    let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    let len = UInt32(letters.length)
    
    var randomString = ""
    
    for _ in 0 ..< length {
        let rand = arc4random_uniform(len)
        var nextChar = letters.character(at: Int(rand))
        randomString += NSString(characters: &nextChar, length: 1) as String
    }
    
    return randomString
}
