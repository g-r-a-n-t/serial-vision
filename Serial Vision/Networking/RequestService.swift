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
    typealias QueryResult = ([CoreComputer]?, String) -> ()
    
    private let hostname: String = "https://recbcct.kube.jamf.build"
    private let credentials: String = "Basic YWRtaW46amFtZjEyMzQ="
    
    var errorMessage = ""
    var dataTask: URLSessionDataTask?
    
    func getComputerRecords(completion: @escaping QueryResult) {
        dataTask?.cancel()
        
        let myURL = NSURL(string: "\(hostname)/JSSResource/computers/subset/basic")
        let request = NSMutableURLRequest(url: myURL! as URL)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(credentials, forHTTPHeaderField: "Authorization")
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
            defer { self.dataTask = nil }
            if let error = error {
                self.errorMessage += "Error response: " + error.localizedDescription + "\n"
            } else if let data = data,
                let response = response as? HTTPURLResponse,
                response.statusCode == 200 {
                self.updateRequestResults(data)
                DispatchQueue.main.async {
                    completion(CoreComputer.getAll(), self.errorMessage)
                }
            }
        }
        task.resume()
    }
    
    func updateComputerUser(id: Int, username: String?) {
        dataTask?.cancel()
        
        let url = "\(hostname)/JSSResource/computers/id/\(id)"
        let xml = """
                <?xml version="1.0" encoding="UTF-8"?>
                <computer>
                  <location>
                    <username>\(username ?? "")</username>
                  </location>
                </computer>
                """
        
        let request = NSMutableURLRequest(url: URL(string: url)!)
        request.httpMethod = "PUT"
        request.httpBody = xml.data(using: String.Encoding.utf8, allowLossyConversion: true)
        request.addValue("text/xml", forHTTPHeaderField: "Content-Type")
        request.addValue(credentials, forHTTPHeaderField: "Authorization")
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
            defer { self.dataTask = nil }
            if let error = error {
                self.errorMessage += "Error response: " + error.localizedDescription + "\n"
            } else {
                print("Successfully updated user in Jamf Pro")
            }
        }
        
        task.resume()
    }
    
    fileprivate func updateRequestResults(_ data: Data) {
        // Sync with the main thread for CoreData modification
        DispatchQueue.main.sync {
            CoreComputer.deleteAll()
        }
        
        var response: JSONDictionary?
        
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
        
        DispatchQueue.main.sync {
            for deviceRecords in array {
                if let deviceRecords = deviceRecords as? JSONDictionary,
                    let id = deviceRecords["id"] as? Int,
                    let serialNumber = deviceRecords["serial_number"] as? String {
                    
                    print("*** Storing serial number: ", serialNumber)
                    
                    let computer = CoreComputer(id: id, serialNumber: serialNumber)
                    
                    computer.username = deviceRecords["username"] as? String
                    computer.deviceName = deviceRecords["name"] as? String
                    computer.department = deviceRecords["department"] as? String
                    computer.building = deviceRecords["building"] as? String
                    
                } else {
                    errorMessage += "Problem parsing trackDictionary\n"
                }
            }
        }
    }
}

