//
//  CoreComputer+CoreDataProperties.swift
//  Serial Vision
//
//  Created by Brandon Roehl on 9/20/18.
//  Copyright © 2018 Jamf. All rights reserved.
//
//

import Foundation
import CoreData


extension CoreComputer {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoreComputer> {
        return NSFetchRequest<CoreComputer>(entityName: "CoreComputer")
    }

    @NSManaged public var id: Int64
    @NSManaged public var deviceName: String?
    @NSManaged public var serialNumber: String
    @NSManaged public var username: String?
    @NSManaged public var building: String?
    @NSManaged public var department: String?
    @NSManaged public var managed: Bool

}
