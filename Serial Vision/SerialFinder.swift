//
//  SerialFinder.swift
//  Serial Vision
//
//  Created by Grant Wuerker on 9/13/18.
//  Copyright © 2018 Jamf. All rights reserved.
//

import Foundation

class SerialFinder {
    
    let serialPrefixes = ["CO"]
    let jamfProSerials = ["CO2T83GXGTFM", "CO2TT83FGRGS"]
    
    func potentialSerials(symbolProbabilitiesList: [[String: Double]]) -> [String: Double] {
        var serials = [String: Double]()
        for serialPrefix in serialPrefixes {
            for i in 0..<symbolProbabilitiesList.count - 11 { // max length for now is 12
                let firstCharacterConfidence = symbolProbabilitiesList[i][String(Array(serialPrefix)[0])]
                let secondCharacterConfidence = symbolProbabilitiesList[i + 1][String(Array(serialPrefix)[1])]
                if(firstCharacterConfidence != nil && secondCharacterConfidence != nil) {
                    // check if there is match with the serial prefix. i.e. "CO2T83GXGTFM" starts with "CO"
                    // since there are only a handful of prefixes, we can filter out most noise checking for this
                    
                    serials = [serialPrefix: firstCharacterConfidence! * secondCharacterConfidence!]
                    for j in i+2..<i+12 { // compute each potential serial number and its probability
                        let oldSerials = serials // a dict in swift is of a Struct, which is a value type. so this copies it
                        serials = [String: Double]()
                        for (oldSerial, oldSerialProbability) in oldSerials {
                            for (symbol, symbolProbability) in symbolProbabilitiesList[j] {
                                serials[oldSerial + symbol] = oldSerialProbability * symbolProbability
                            }
                        }
                    }
                }
            }
            
            return serials
        }
        
        return [String: Double]()
    }
}
