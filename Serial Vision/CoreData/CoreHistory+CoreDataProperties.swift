//
//  CoreHistory+CoreDataProperties.swift
//  Serial Vision
//
//  Created by Brandon Roehl on 9/20/18.
//  Copyright © 2018 Jamf. All rights reserved.
//
//

import Foundation
import CoreData


extension CoreHistory {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoreHistory> {
        return NSFetchRequest<CoreHistory>(entityName: "CoreHistory")
    }

    @NSManaged public var serialNumber: String
    @NSManaged public var date: NSDate

}
