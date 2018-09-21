//
//  CoreComputer+CoreDataClass.swift
//  Serial Vision
//
//  Created by Brandon Roehl on 9/20/18.
//  Copyright © 2018 Jamf. All rights reserved.
//
//

import UIKit
import CoreData

@objc(CoreComputer)
public class CoreComputer: NSManagedObject {
    static func get(from predicate: NSPredicate?) -> [CoreComputer] {
        var fetchResults: [CoreComputer] = []
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let moc: NSManagedObjectContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<CoreComputer> = CoreComputer.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        fetchRequest.predicate = predicate
        
        do {
            fetchResults = try moc.fetch(fetchRequest)
        } catch {
            print("Error: Can't fetch \(fetchRequest)")
        }
        return fetchResults
    }
    
    static func getAll() -> [CoreComputer] {
        return self.get(from: nil)
    }
    
    static func get(id: Int) -> CoreComputer? {
        let predicate = NSPredicate(format: "id == %ld", id)
        return self.get(from: predicate).first
    }
    
    static func get(serial: String) -> CoreComputer? {
        let predicate = NSPredicate(format: "serialNumber == %s", serial)
        return self.get(from: predicate).first
    }
    
    static func getCount(from predicate: NSPredicate?) -> Int {
        var fetchResults = 0
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let moc: NSManagedObjectContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<CoreComputer> = CoreComputer.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        fetchRequest.predicate = predicate
        
        do {
            fetchResults = try moc.count(for: fetchRequest)
        } catch {
            print("Error: Can't fetch \(fetchRequest)")
        }
        return fetchResults
    }
    
    static func deleteAll() {
        let moc: NSManagedObjectContext = AppDelegate.main.persistentContainer.viewContext
        self.get(from: nil).forEach(moc.delete)
    }
    
    convenience init(id: Int, deviceName: String, serialNumber: String, username: String) {
        let moc: NSManagedObjectContext = AppDelegate.main.persistentContainer.viewContext
        
        self.init(context: moc)
        
        self.id = Int64(id)
        self.deviceName = deviceName
        self.serialNumber = serialNumber
        self.username = username
    }
}
