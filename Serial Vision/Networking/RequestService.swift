//
//  RequestService.swift
//  Serial Vision
//
//  Created by David Brazeau on 9/18/18.
//  Copyright © 2018 Jamf. All rights reserved.
//

import Foundation

class RequestService {
    
    typealias JSONDictionary = [String: Any]
    typealias QueryResult = ([MobileDeviceRecord]?, String) -> ()
    
    var records: [MobileDeviceRecord] = []
    var errorMessage = ""
    
    var dataTask: URLSessionDataTask?
    
    
    func getMobileDevices(completion: @escaping QueryResult) {
        dataTask?.cancel()
        let credentials = JamfPro.init()
        let mobileDeviceUrl = URL(string: "https://recbcct.kube.jamf.build/JSSResource/computers/subset/basic")
        let credential = URLCredential(user: credentials.username, password: credentials.password, persistence: URLCredential.Persistence.forSession)
        
        let protectionSpace = URLProtectionSpace(host: "recbcct.kube.jamf.build", port: 443, protocol: "https", realm: "Restricted", authenticationMethod: NSURLAuthenticationMethodHTTPBasic)
        URLCredentialStorage.shared.setDefaultCredential(credential, for: protectionSpace)
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        dataTask = session.dataTask(with: mobileDeviceUrl!) { data, response, error in
            defer { self.dataTask = nil }
            if let error = error {
                self.errorMessage += "DataTask error: " + error.localizedDescription + "\n"
            } else if let data = data,
                let response = response as? HTTPURLResponse,
                response.statusCode == 200 {
                self.updateRequestResults(data)
                DispatchQueue.main.async {
                    completion(self.records, self.errorMessage)
                }
            }
        }
        dataTask?.resume()
    }
    
    fileprivate func updateRequestResults(_ data: Data) {
        var response: JSONDictionary?
        records.removeAll()
        
        do {
            response = try JSONSerialization.jsonObject(with: data, options: []) as? JSONDictionary
        } catch let parseError as NSError {
            errorMessage += "JSONSerialization error: \(parseError.localizedDescription)\n"
            return
        }
        
        guard let array = response!["computers"] as? [Any] else {
            errorMessage += "Request has not results\n"
            return
        }
        
        for deviceRecords in array {
            if let deviceRecords = deviceRecords as? JSONDictionary,
                let id = deviceRecords["id"] as? Int,
                let deviceName = deviceRecords["name"] as? String,
                let serialNumber = deviceRecords["serial_number"] as? String,
                let username = deviceRecords["username"] as? String {
                
                print("*** Storing serial number: ", serialNumber)
                
                records.append(MobileDeviceRecord(id: id, deviceName: deviceName, serialNumber: serialNumber, username: username))
            } else {
                errorMessage += "Problem parsing trackDictionary\n"
            }
        }
    }
}

