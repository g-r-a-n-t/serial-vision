//
//  CoreData+utils.swift
//  Serial Vision
//
//  Created by Brandon Roehl on 9/20/18.
//  Copyright © 2018 Jamf. All rights reserved.
//

import UIKit
import CoreData

extension NSManagedObject {
    func delete() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let moc: NSManagedObjectContext = appDelegate.persistentContainer.viewContext
        // Delete
        moc.delete(self)
    }
}
