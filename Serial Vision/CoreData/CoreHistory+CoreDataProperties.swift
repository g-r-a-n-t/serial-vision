//
//  CoreSerial+CoreDataProperties.swift
//  Serial Vision
//
//  Created by Brandon Roehl on 9/17/18.
//  Copyright © 2018 Jamf. All rights reserved.
//
//

import Foundation
import CoreData


extension CoreHistory {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoreHistory> {
        return NSFetchRequest<CoreHistory>(entityName: "CoreSerial")
    }

    @NSManaged public var code: String?
    @NSManaged public var date: NSDate?

}
