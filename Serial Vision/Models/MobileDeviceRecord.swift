//
//  MobileDeviceRecord.swift
//  Serial Vision
//
//  Created by David Brazeau on 9/18/18.
//  Copyright © 2018 Jamf. All rights reserved.
//

import Foundation

class MobileDeviceRecord {
    
    let id: Int
    let deviceName: String
    let serialNumber: String
    let username: String
    
    init(id: Int, deviceName: String, serialNumber: String, username: String) {
        self.id = id
        self.deviceName = deviceName
        self.serialNumber = serialNumber
        self.username = username
    }
}
