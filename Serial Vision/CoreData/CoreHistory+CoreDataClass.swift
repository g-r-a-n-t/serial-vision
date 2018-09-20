//
//  CoreSerial+CoreDataClass.swift
//  Serial Vision
//
//  Created by Brandon Roehl on 9/17/18.
//  Copyright © 2018 Jamf. All rights reserved.
//
//

import UIKit
import CoreData

@objc(CoreHistory)
public class CoreHistory: NSManagedObject {
    static func get(from predicate: NSPredicate?) -> [CoreHistory] {
        var fetchResults: [CoreHistory] = []
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let moc: NSManagedObjectContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<CoreHistory> = CoreHistory.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        fetchRequest.predicate = predicate
        
        do {
            fetchResults = try moc.fetch(fetchRequest)
        } catch {
            print("Error: Can't fetch \(fetchRequest)")
        }
        return fetchResults
    }
    
    static func getAll() -> [CoreHistory] {
        return self.get(from: nil)
    }
    
    static func getCount(from predicate: NSPredicate?) -> Int {
        var fetchResults = 0
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let moc: NSManagedObjectContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<CoreHistory> = CoreHistory.fetchRequest()
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
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let moc: NSManagedObjectContext = appDelegate.persistentContainer.viewContext
        self.get(from: nil).forEach(moc.delete)
    }
    
    convenience init(serialNumber: String) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let moc: NSManagedObjectContext = appDelegate.persistentContainer.viewContext
        
        self.init(context: moc)
        
        self.serialNumber = serialNumber
        self.date = Date() as NSDate
    }
}
