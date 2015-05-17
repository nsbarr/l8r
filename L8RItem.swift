//
//  L8RItem.swift
//  l8r
//
//  Created by nick barr on 5/16/15.
//  Copyright (c) 2015 poemsio. All rights reserved.
//

import Foundation
import CoreData

class L8RItem: NSManagedObject {

    @NSManaged var dueDate: NSDate?
    @NSManaged var imageData: NSData?
    @NSManaged var text: String?
    
    lazy var objectIDString:String! = {
        self.objectID.URIRepresentation().absoluteString
    }()

}
