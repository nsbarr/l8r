//
//  InboxController.swift
//  l8r
//
//  Created by nick barr on 5/16/15.
//  Copyright (c) 2015 poemsio. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class InboxController: UIViewController {
    
    //MARK: - Variables

    
    @IBOutlet weak var cardStackView:CardStack!
    
    var l8rsById:[String:L8RItem]!
    
    var currentL8R:L8RItem! {

        if let topCard = self.cardStackView.topCard {
            if let cardId = topCard.cardId {
                
                return l8rsById[cardId]!
            }
            else {
                println("error, received topCard but no cardId")
            }
        }
        else {
            println("possible error, topCard was nil")
        }
        return nil
    }
    
    var cardCount: Int {
        println("Card Count:\(self.l8rsById.count)")
        
        return self.l8rsById.count
    }
    
    var inboxNumber: UILabel!
    var appDelegate: AppDelegate!
    var managedContext: NSManagedObjectContext!
    
    //MARK: - Lifecycle

    
    override func viewDidLoad() {
        println("inbox")
    }
}