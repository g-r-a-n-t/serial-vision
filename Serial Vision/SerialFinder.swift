//
//  SerialFinder.swift
//  Serial Vision
//
//  Created by Grant Wuerker on 9/13/18.
//  Copyright © 2018 Jamf. All rights reserved.
//

import Foundation

class SerialFinder {
    var serialLength: Int
    var jamfProPartialSerials: Set<String>
    
    init(serialLength: Int, jamfProSerials: [String]) {
        self.serialLength = serialLength
        self.jamfProPartialSerials = Set<String>()
        self.setJamfProSerials(serials: jamfProSerials)
    }
    
    func mergeDicts <K, V> (left: [K:V], right: [K:V]) -> [K:V] {
        var result = left
        for (k, v) in right {
            result[k] = v
        }
        
        return result
    }
    
    private func setJamfProSerials(serials: [String]) {
        // by adding every possible front part of each serial number, we will be able to prune non-existent serials
        // in the potentialSerials method before building out each possible variation
        for serial in serials {
            var serialFront = ""
            for character in serial {
                serialFront.append(character)
                jamfProPartialSerials.insert(serialFront)
            }
        }
    }
    
    func potentialSerials(characterProbabilityDistributions: [[String: Double]]) -> [String: Double] {
        var serials = [String: Double]()
        for i in 0...characterProbabilityDistributions.count - self.serialLength {
            // iterate over each character distribution section of length "serialLength"
            var partialSerials = ["":1.0] // serial dictionary contains an empty string with 100% probability at beginning
            for j in i..<i+12 { // go through each character distribution in
                var newPartialSerials = [String: Double]() // create a temporary dictionary containing new serials
                for (partialSerial, partialSerialProbability) in partialSerials {
                    for (character, characterProbability) in characterProbabilityDistributions[j] {
                        let newPartialSerial = partialSerial + character
                        if jamfProPartialSerials.contains(newPartialSerial) {
                            newPartialSerials[newPartialSerial] = partialSerialProbability * characterProbability
                        }
                    }
                }
                partialSerials = newPartialSerials
            }
            serials = mergeDicts(left: serials, right: partialSerials) // add new serials of length j
        }
        return serials
    }
}
