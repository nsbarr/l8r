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
    
    var actionButton: UIButton!
    var actionButtonTitle: UIButton!
    var shareButton: UIButton!
    var snapButton: UIButton!
    var backButton: UIButton!
    var containerView: UIView!
    var extraL8rsContainerView: UIView!
    var datePicker: UIDatePicker!



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

        self.addSnapButton()
        self.addBackButton()
        self.addActionButton()
        self.addShareButton()
        
        self.fetchL8rs()

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
    
    func addBackButton(){
        backButton = UIButton(frame: CGRectMake(10, 20, 40, 40))
        backButton.setImage(UIImage(named: "backButtonImage"), forState: .Normal)
        backButton.addTarget(self, action: Selector("backToCamera:"), forControlEvents: .TouchUpInside)
        view.addSubview(backButton)
    }
    
    func backToCamera(sender: UIButton){
        let pvc = self.parentViewController as! UIPageViewController
        
        let appDelegate  = UIApplication.sharedApplication().delegate as! AppDelegate
        let viewController = appDelegate.window!.rootViewController as! ViewController
        let cc = viewController.viewControllerAtIndex(1)
        pvc.setViewControllers([cc], direction: UIPageViewControllerNavigationDirection.Reverse, animated: true, completion: nil)
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
        
        //this should be cued off "bottom card is showing" not # of l8rs
        
        if l8rsById.count == 0 {
            snapButton.hidden = true
            shareButton.hidden = true
            actionButton.hidden = true
        }
        else {
            snapButton.hidden = false
            shareButton.hidden = false
            actionButton.hidden = false
        }

    }


    func updateButtonFrames() {
        self.snapButton.frame = CGRect(x: 0, y: view.frame.height-90, width: 60, height: 60)
        snapButton.center.x = view.center.x-40
        self.actionButton.frame = CGRect(x: snapButton.center.x+60, y: snapButton.frame.origin.y, width: 60, height: 60)
        self.shareButton.frame = CGRect(x: actionButton.center.x+60, y: snapButton.frame.origin.y, width: 60, height: 60)
    }
    
    func addSnapButton(){
        snapButton = UIButton(frame: CGRect(x: 0, y: view.frame.height-64, width: 60, height: 60))
        snapButton.center.x = view.center.x
        snapButton.tag = 0
        let buttonImage = UIImage(named: "inboxSnapButtonImage")
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
    
    
    func addActionButton(){
        actionButton = UIButton(frame: CGRect(x: 28, y: view.frame.height-64, width: 60, height: 60))
        actionButton.center.x = snapButton.center.x+100
        actionButton.setTitle("", forState: .Normal)
        actionButton.setImage(UIImage(named: "actionButtonImage"), forState: .Normal)
        actionButton.setImage(UIImage(named: "actionButtonImageEmpty"), forState: UIControlState.Selected)
        actionButton.addTarget(self, action: Selector("openActionSheet:"), forControlEvents: .TouchUpInside)
        actionButton.titleLabel?.font = UIFont(name: "Arial-BoldMT", size: 40)
        actionButton.titleLabel!.layer.shadowColor = UIColor.blackColor().CGColor
        actionButton.titleLabel!.layer.shadowOffset = CGSizeMake(0, 1)
        actionButton.titleLabel!.layer.shadowOpacity = 1
        actionButton.titleLabel!.layer.shadowRadius = 1
        cardStackView.addSubview(actionButton)
        
        
        actionButtonTitle = UIButton(frame: actionButton.frame)
        actionButtonTitle.setTitle("", forState: .Normal)
        actionButtonTitle.addTarget(self, action: Selector("openActionSheet:"), forControlEvents: .TouchUpInside)
        actionButtonTitle.titleLabel!.font = UIFont(name: "Arial-BoldMT", size: 32)
        actionButtonTitle.titleLabel!.layer.shadowColor = UIColor.blackColor().CGColor
        actionButtonTitle.titleLabel!.layer.shadowOffset = CGSizeMake(0, 1)
        actionButtonTitle.titleLabel!.layer.shadowOpacity = 1
        actionButtonTitle.titleLabel!.layer.shadowRadius = 1
        actionButton.addSubview(actionButtonTitle)
        actionButtonTitle.center = actionButton.convertPoint(actionButton.center, fromView: actionButton.superview)
     //   actionButtonTitle.center = actionButton.center
     //   cardStackView.addSubview(actionButtonTitle)

    }
    
    func addShareButton(){
        shareButton = UIButton(frame: CGRect(x: view.frame.width-80, y: view.frame.height-130, width: 60, height: 60))
        let buttonImage = UIImage(named: "shareButtonImage")
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
        
        extraL8rsContainerView = UIView(frame: self.view.frame)
        self.view.addSubview(extraL8rsContainerView)
        
        //var buttonImage = ["dateImage", "placeImage", "personImage"]
        var tag = [1,2,3]
        var xPos = [60, extraL8rsContainerView.frame.midX, extraL8rsContainerView.frame.width-(60)]
        var buttonIndex = 0
        
        for buttonImage in ["placeImage", "calendarImage", "personImage"]{
            
            let button = UIButton(frame: CGRectMake(extraL8rsContainerView.frame.midX-42, self.view.frame.height, 85, 93))
            //button.setTitle(buttonTitle, forState: .Normal)
            button.setImage(UIImage(named: buttonImage), forState: UIControlState.Normal)
            button.titleLabel?.font = UIFont(name: "Arial-BoldMT", size: 32)
            button.addTarget(self, action: Selector("extraL8rPressed:"), forControlEvents: .TouchUpInside)
            button.titleLabel!.layer.shadowColor = UIColor.blackColor().CGColor
            button.titleLabel!.layer.shadowOffset = CGSizeMake(0, 1)
            button.titleLabel!.layer.shadowOpacity = 1
            button.titleLabel!.layer.shadowRadius = 1
            button.transform = CGAffineTransformMakeScale(0,0)
            button.alpha = 1
            button.tag = tag[buttonIndex]
            extraL8rsContainerView.addSubview(button)
            
            UIView.animateKeyframesWithDuration(0.3, delay: 0, options: nil, animations: { () -> Void in
                button.alpha = 1
                button.center.y = self.view.center.y
                button.center.x = xPos[buttonIndex]
                button.transform = CGAffineTransformMakeScale(1.0,1.0)
                }, completion: nil)
            
            buttonIndex = buttonIndex + 1
        }

    }
    
    func extraL8rPressed(sender: UIButton){
        
        if sender.tag == 2 {
            self.showDatePicker()
            self.hideExtraL8rOptions()
        }
        
    }
    
    func showDatePicker(){
        
        var datePickerView = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
        datePickerView.frame = self.view.frame
        self.view.addSubview(datePickerView)
        
        datePicker = UIDatePicker(frame: self.view.frame)
        datePicker.center.y = self.view.center.y
        datePicker.minuteInterval = 30
        datePickerView.addSubview(datePicker)
        
        let confirmButton = UIButton(frame: CGRectMake(0, 200, 100, 100))
        confirmButton.center.x = self.view.center.x
        confirmButton.center.y = datePicker.frame.maxY+60
        confirmButton.setImage(UIImage(named: "inboxSnapButtonImage"), forState: .Normal)
        confirmButton.tag = 777
        confirmButton.addTarget(self, action: Selector("respondToGesture:"), forControlEvents: .TouchUpInside)
        datePickerView.addSubview(confirmButton)
    }
    
    func updateL8rFromDatePicker(sender: UIButton){
        
        dispatch_async(dispatch_get_main_queue(), {   ()->Void in
            
            self.updateL8rWithDate(self.datePicker.date)
        })
    }
    
    
    func hideExtraL8rOptions(){
        self.extraL8rsContainerView.subviews.map({ $0.removeFromSuperview() })
        extraL8rsContainerView.removeFromSuperview()
    }
    
    
    func respondToGesture(sender: AnyObject){
        if sender.isKindOfClass(UILongPressGestureRecognizer){
            println("longpress")
            self.showExtraL8rOptions()
        }
        else if sender.isKindOfClass(UITapGestureRecognizer){
            println("tap")
            
            //tomorrow at 9am
            var scheduledDate: NSDate!
            var theCalendar = NSCalendar.currentCalendar()
            let currentTime = NSDate()
            let tomorrowComponent = NSDateComponents()
            tomorrowComponent.day = 1
            let tomorrow = theCalendar.dateByAddingComponents(tomorrowComponent, toDate: currentTime, options: NSCalendarOptions(0))
            let tomorrowAt9AmComponents = theCalendar.components(NSCalendarUnit.CalendarUnitCalendar|NSCalendarUnit.CalendarUnitYear|NSCalendarUnit.CalendarUnitMonth|NSCalendarUnit.CalendarUnitDay, fromDate: tomorrow!)
            tomorrowAt9AmComponents.hour = 9
            scheduledDate = theCalendar.dateFromComponents(tomorrowAt9AmComponents)
//            
//            //in a minute (for testing)
//            let timeComponent = NSDateComponents()
//            timeComponent.minute = 1
//            scheduledDate = theCalendar.dateByAddingComponents(timeComponent, toDate: currentTime, options: NSCalendarOptions(0))
            
            
            self.updateL8rWithDate(scheduledDate)
            self.flashConfirm()
            self.dismissTopCard()
            self.fetchL8rs()

        }
            
        else if sender is UIButton {
            println("Received from Date Picker")
            
            let scheduledDate = self.datePicker.date
            self.updateL8rWithDate(scheduledDate)

            let viewToDisappear = sender.superview!
            viewToDisappear!.subviews.map({ $0.removeFromSuperview() })
            viewToDisappear?.removeFromSuperview()
            
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
    
    func cardMovedToTop(card: Card) {
        
        
        dispatch_async(dispatch_get_main_queue(), {   ()->Void in
            
            self.actionButtonTitle.selected = false

        
            println("text of currentL8R is \(self.currentL8R.text)")
            if self.currentL8R?.text == "Mad Max" {
                println("its a movie")
                
                //TODO: Why is this super duper slow
                self.actionButtonTitle.selected = true
                self.actionButtonTitle.setTitle("🎬", forState: UIControlState.Normal)

            }
            else {
                println("it's not a movie")
                self.actionButtonTitle.setTitle("", forState: .Normal)

            }
        })
    }
    
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
    
    func openActionSheet(sender: UIButton){
        println("opening smart do")
        println("label is \(sender.titleLabel)")
        if sender.titleLabel?.text == "🎬"{
            println("opening movie")

            UIApplication.sharedApplication().openURL(NSURL(string:"http://www.fandango.com/pavilionparkslope_aaefw/theaterpage")!)
            
        }
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