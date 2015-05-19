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

class InboxController: UIViewController, UIGestureRecognizerDelegate, CardStackDelegate, UITextViewDelegate {
    
    //MARK: - Variables

    
    @IBOutlet weak var cardStackView:CardStack!
    
    var dismissButton: UIButton!
    var shareButton: UIButton!
    var snapButton: UIButton!
    var containerView: UIView!


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
        super.viewDidLoad()
        self.setUpCoreData()
        self.fetchL8rs()

        self.addSnapButton()
        self.addDismissButton()
        self.addShareButton()
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(false)
        println("view will appear")

        self.fetchL8rs()
        self.cardStackView.delegate = self
        self.cardStackView.loadStack()
        self.updateButtonFrames()
        
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(false)
        println("view will disappear")

        self.cardStackView.unloadStack()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    
    func fetchL8rs(){
        
        let fetchRequest = NSFetchRequest(entityName: "L8RItem")
        var error: NSError?
        
        let fetchedResults = managedContext.executeFetchRequest(fetchRequest, error: &error) as! [NSManagedObject]?
        let currentDate = NSDate()
        
        self.l8rsById = [String:L8RItem]()
        
        if let results = fetchedResults {
            for anItem in results {
                if let l8rItem = anItem as? L8RItem {
                    //TODO: Diego doesn't like this
                    println("checking item at date  \(l8rItem.dueDate)")
                    if currentDate.compare(l8rItem.dueDate!) == NSComparisonResult.OrderedDescending {
                        l8rsById[l8rItem.objectIDString] = l8rItem
                    }
                }
                else {
                    let cname = NSStringFromClass(anItem.dynamicType)
                    NSLog("item is not a L8R! class name is \(cname)")
                }
                
            }
        }
        else {
            println("Could not fetch \(error), \(error!.userInfo)")
        }
    }


    func updateButtonFrames() {
        self.snapButton.frame = CGRect(x: 0, y: view.frame.height-130, width: 100, height: 100)
        snapButton.center.x = view.center.x
        self.dismissButton.frame = CGRect(x: 40, y: view.frame.height-130, width: 60, height: 60)
        self.shareButton.frame = CGRect(x: view.frame.width-100, y: view.frame.height-130, width: 60, height: 60)
    }
    
    func addSnapButton(){
        snapButton = UIButton(frame: CGRect(x: 0, y: view.frame.height-120, width: 100, height: 100))
        snapButton.center.x = view.center.x
        snapButton.tag = 0
        let buttonImage = UIImage(named: "snapButtonImage")
        snapButton.setImage(buttonImage, forState: .Normal)
        snapButton.hidden = false
        
        let tap = UITapGestureRecognizer(target: self, action: Selector("l8rButtonTapped:"))
        snapButton.addGestureRecognizer(tap)
        tap.delegate = self
        
        let longpress = UILongPressGestureRecognizer(target: self, action: Selector("l8rButtonLongpressed:"))
        longpress.minimumPressDuration = 0.2
        snapButton.addGestureRecognizer(longpress)
        longpress.delegate = self
        
        cardStackView.addSubview(snapButton)
    }
    
    func addDismissButton(){
        dismissButton = UIButton(frame: CGRect(x: 28, y: view.frame.height-130, width: 60, height: 60))
        let buttonImage = UIImage(named: "dismissButton")
        dismissButton.center.x = snapButton.center.x-100
        dismissButton.setImage(buttonImage, forState: .Normal)
        dismissButton.addTarget(self, action: Selector("dismissTopCard"), forControlEvents: .TouchUpInside)
        cardStackView.addSubview(dismissButton)
    }
    
    func addShareButton(){
        shareButton = UIButton(frame: CGRect(x: view.frame.width-80, y: view.frame.height-130, width: 60, height: 60))
        let buttonImage = UIImage(named: "shareButton")
        shareButton.center.x = snapButton.center.x+100
        shareButton.setImage(buttonImage, forState: .Normal)
        shareButton.addTarget(self, action: Selector("openShareSheet:"), forControlEvents: .TouchUpInside)
        cardStackView.addSubview(shareButton)
    }
    
    func l8rButtonTapped(sender: UITapGestureRecognizer){
        self.respondToGesture(sender)
    }
    
    func l8rButtonLongpressed(sender: UILongPressGestureRecognizer){
        if sender.state == .Began{
            self.respondToGesture(sender)
        }
    }
    
    func showExtraL8rOptions(){
        
        containerView = UIView(frame: self.view.frame)
        self.view.addSubview(containerView)
        
        var buttonYPos:CGFloat = 100
        
        
        for buttonTitle in ["Date", "Place", "Person"]{
            buttonYPos = buttonYPos + 100
            let button = UIButton(frame: CGRectMake(60, buttonYPos, containerView.frame.width, 60))
            button.setTitle(buttonTitle, forState: .Normal)
            //  flipButton.setImage(UIImage(named: "flipButton"), forState: .Normal)
            button.titleLabel?.font = UIFont(name: "Arial-BoldMT", size: 32)
            button.addTarget(self, action: Selector("extraL8rPressed:"), forControlEvents: .TouchUpInside)
            button.titleLabel!.layer.shadowColor = UIColor.blackColor().CGColor
            button.titleLabel!.layer.shadowOffset = CGSizeMake(0, 1)
            button.titleLabel!.layer.shadowOpacity = 1
            button.titleLabel!.layer.shadowRadius = 1
            containerView.addSubview(button)
        }
    }
    
    func respondToGesture(sender: UIGestureRecognizer){
        if sender.isKindOfClass(UILongPressGestureRecognizer){
            println("longpress")
            self.showExtraL8rOptions()
        }
        else if sender.isKindOfClass(UITapGestureRecognizer){
            println("tap")
            
            var scheduledDate: NSDate!
            var theCalendar = NSCalendar.currentCalendar()
            let currentTime = NSDate()
            let tomorrowComponent = NSDateComponents()
            tomorrowComponent.day = 1
            let tomorrow = theCalendar.dateByAddingComponents(tomorrowComponent, toDate: currentTime, options: NSCalendarOptions(0))
            let tomorrowAt9AmComponents = theCalendar.components(NSCalendarUnit.CalendarUnitCalendar|NSCalendarUnit.CalendarUnitYear|NSCalendarUnit.CalendarUnitMonth|NSCalendarUnit.CalendarUnitDay, fromDate: tomorrow!)
            tomorrowAt9AmComponents.hour = 9
            scheduledDate = theCalendar.dateFromComponents(tomorrowAt9AmComponents)
            
            self.updateL8rWithDate(scheduledDate)
            self.flashConfirm()
            self.dismissTopCard()
            self.fetchL8rs()

        }
        else {
            println("kind of class is \(sender)")
        }

    }
    
    func flashConfirm(){
        let flashConfirm = UIImageView(frame: CGRect(x:0, y: 0, width: self.view.frame.width-100, height: self.view.frame.width-100))
        flashConfirm.center = self.view.center
        flashConfirm.image = UIImage(named: "flashConfirmImage")
        flashConfirm.contentMode = UIViewContentMode.ScaleAspectFit
        flashConfirm.alpha = 1
        self.view.addSubview(flashConfirm)
        
        UIView.animateKeyframesWithDuration(0.5, delay: 0.3, options: nil, animations: { () -> Void in
            flashConfirm.alpha = 0
            flashConfirm.frame = CGRectMake(self.view.frame.midX, self.view.frame.midY, 0, 0)
            }, completion: nil)
    }
    
    func updateL8rWithDate(scheduledDate: NSDate){
        
        dispatch_async(dispatch_get_main_queue(), {   ()->Void in
            
            self.currentL8R.dueDate = scheduledDate
            var error: NSError?
            self.managedContext.save(&error)
            
            if !self.managedContext.save(&error) {
                println("Unresolved error \(error), \(error!.userInfo)")
                abort()
            }
            else {
                self.scheduleLocalNotificationWithDueDate(scheduledDate)
            }
            
            
        })
        
    }
    
    
    
    func scheduleLocalNotificationWithDueDate(dueDate: NSDate) {
        println("scheduling notification with date \(dueDate)")
        var localNotification = UILocalNotification()
        localNotification.fireDate = dueDate
        localNotification.alertBody = "A L8R just arrived for you"
        localNotification.alertAction = "View"
        localNotification.category = "l8rReminderCategory"
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
    }
    
    //MARK: - Actions
    
    func dismissTopCard(){
        self.cardStackView.swipeOutTopCardWithSpeed(1.0)
    }
    
    func inboxButtonPressed(sender:UIButton){
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    
    func openShareSheet(sender: UIButton){
        var sharingItems = [AnyObject]()
        
        let text = "Check out this L8R and create your own!"
        sharingItems.append(text)
        
        if let image = UIImage(data: self.currentL8R.imageData!, scale: 0.0) {
            sharingItems.append(image)
        }
        
        let url = NSURL(string: "http://lthenumbereightr.com")
        sharingItems.append(url!)
        
        let activityViewController = UIActivityViewController(activityItems: sharingItems, applicationActivities: nil)
        self.presentViewController(activityViewController, animated: true, completion: nil)
        
    }
    //MARK: - Card delegate Methods
    
    func cardRemoved(card: Card) {
        println("The card \(card.cardId!) was removed!")
        
        if let cardToRemove = self.currentL8R as L8RItem? {
            
            
            dispatch_async(dispatch_get_main_queue(), {   ()->Void in
                
                self.managedContext.deleteObject(cardToRemove)
                
                var error: NSError?
                
                if !self.managedContext.save(&error) {
                    println("Unresolved error \(error), \(error!.userInfo)")
                    abort()
                }
                
                self.l8rsById.removeValueForKey(card.cardId!)
                self.fetchL8rs()
            })
        }
        else {
            println("card to remove is nil! aieeee! \(card)")
        }
    }
    
    
    func cardAtIndex(index: Int, frame: CGRect) -> Card {
        var l8rs:[L8RItem] = []
        l8rs = l8rsById.values.array
        println("Array Count: \(l8rs.count)")
        
        
        var dateDescriptor = NSSortDescriptor(key: "fireDateSort", ascending: true)
        
        l8rs.sort { $0.dueDate!.compare($1.dueDate!) == NSComparisonResult.OrderedAscending }
        var uniqueId = "help"

        if index > 1 {
            println("Next item in array:\(index)")
            uniqueId = l8rs[2].objectIDString
        }
        else {
            println("Seeding with first l8rs")
            uniqueId = l8rs[index].objectIDString
        }
        
        
        let imageData = l8rsById[uniqueId]?.imageData
        let image = UIImage(data: imageData!, scale: 1.0)!
        //       let ratio = frame.height/image.size.height
        
        println("frame passed in: \(frame)")
        let card: Card = Card(frame: frame)
        
        let cardImageView = UIImageView(frame:card.frame)
        
        cardImageView.contentMode = UIViewContentMode.ScaleAspectFill
        cardImageView.image = image
        
        card.addSubview(cardImageView)
        card.addSubview(addTextViewWithText(l8rsById[uniqueId]!.text!, position: l8rsById[uniqueId]!.textPosition!))

        card.cardId = uniqueId
        card.center.x = view.center.x
        
        card.clipsToBounds = true
        
        return card
    }
    
    func addTextViewWithText(text:String, position:String) -> UITextView{
        
        let textView = UITextView(frame: self.view.frame)
        textView.editable = false
        
        textView.backgroundColor = UIColor.clearColor()
        textView.returnKeyType = UIReturnKeyType.Done
        textView.delegate = self
        
        let font = UIFont(name: "Dosis-Bold", size: 42.0)!
        let textStyle = NSMutableParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
        textStyle.alignment = NSTextAlignment.Center
        let textColor = UIColor.whiteColor()
        
        var shadow = NSShadow()
        shadow.shadowColor = UIColor.blackColor()
        shadow.shadowOffset = CGSizeMake(2.0,2.0)
        
        let attr = [
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: textColor,
            NSParagraphStyleAttributeName: textStyle,
            NSShadowAttributeName: shadow
        ]
        
        textView.attributedText = NSAttributedString(string: text, attributes: attr)
        textView.textAlignment = .Center

        let fixedWidth = textView.frame.size.width
        let newSize = textView.sizeThatFits(CGSizeMake(fixedWidth, CGFloat(MAXFLOAT)))
        var newFrame = textView.frame
        newFrame.size = CGSizeMake(CGFloat(fmaxf(Float(newSize.width), Float(fixedWidth))), newSize.height)
        textView.frame = newFrame

        
        let center = CGPointFromString(position)
        textView.center = center
        
        
        return textView
        
    }
    
    
    func setUpCoreData(){
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        managedContext = appDelegate.managedObjectContext!
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    



    
}