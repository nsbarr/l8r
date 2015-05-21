//
//  CameraController.swift
//  l8r
//
//  Created by nick barr on 5/16/15.
//  Copyright (c) 2015 poemsio. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import CoreData



class CameraController: UIViewController, UIGestureRecognizerDelegate, UITextViewDelegate {
    
    
    //  MARK: - Variables
    //camera setup
    var previewLayer : AVCaptureVideoPreviewLayer?
    var backCameraDevice:AVCaptureDevice?
    var frontCameraDevice:AVCaptureDevice?
    var stillCameraOutput:AVCaptureStillImageOutput!
    let session = AVCaptureSession()
    var currentInput: AVCaptureDeviceInput?
    var currentDeviceIsBack = true
    var sessionQueue = dispatch_queue_create("com.example.camera.capture_session", DISPATCH_QUEUE_SERIAL)

    //hud setup
    var snapButton:UIButton!
    var flipButton:UIButton!
    var extraL8rsContainerView: UIView!
    var imageContainerView: UIView!
    var inboxButton: UIButton!
    var inboxButtonFill: UIButton!
    var datePicker: UIDatePicker!
    

    //text setup
    var textView: UITextView!
    var l8rText = String()
    var pan: UIPanGestureRecognizer?
    var textViewPosition: CGPoint!
    
    //core data setup
    var appDelegate: AppDelegate!
    var managedContext: NSManagedObjectContext!
    var l8rsById:[String:L8RItem]!



    
    //image setup
    var snapshotImage: UIImage!
    


    //MARK: - View Lifecycle
    
    override func viewDidLoad() {
        println("camera")
        self.setUpCamera()
        self.addTextView()
        self.addTextButton()
        self.addFlipButton()
        self.addSnapButton()
        self.addInboxButton()

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(false)
        self.setUpCoreData()
        self.fetchL8rs()
    }
    
    func setUpCoreData(){
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        managedContext = appDelegate.managedObjectContext!
    }
    
    func setUpCamera(){
        let availableCameraDevices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
        for device in availableCameraDevices as! [AVCaptureDevice] {
            if device.position == .Back {
                backCameraDevice = device
            }
            else if device.position == .Front {
                frontCameraDevice = device
            }
        }
        
        var error:NSError?
        let possibleCameraInput: AnyObject? = AVCaptureDeviceInput.deviceInputWithDevice(backCameraDevice, error: &error)
        if let backCameraInput = possibleCameraInput as? AVCaptureDeviceInput {
            if self.session.canAddInput(backCameraInput) {
                currentInput = backCameraInput
                self.session.addInput(currentInput)
            }
        }
        
        stillCameraOutput = AVCaptureStillImageOutput()
        
        if self.session.canAddOutput(self.stillCameraOutput) {
            self.session.addOutput(self.stillCameraOutput)
        }
        
        //this auto-handles focus, WB, exposure, etc.
        session.sessionPreset = AVCaptureSessionPresetPhoto
        
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        self.view.layer.addSublayer(previewLayer)
        previewLayer?.frame = view.bounds
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        dispatch_async(sessionQueue) { () -> Void in
            self.session.startRunning()
        }
        previewLayer?.connection.enabled = true
        
        
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
        
        if l8rsById.count > 0 {
            UIView.animateWithDuration(1.0, animations: { () -> Void in
                self.inboxButtonFill.alpha = 1
            })
        }
        else {
            UIView.animateWithDuration(0.6, animations: { () -> Void in
                self.inboxButtonFill.alpha = 0
            })

        }
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
        
        view.addSubview(snapButton)
    }
    
    func addInboxButton(){
        
        //TODO: - don't hardcode this
    
        inboxButton = UIButton(frame: CGRectMake(self.view.frame.width-(20+30),self.view.frame.height-60, 30, 30))
        inboxButton.addTarget(self, action: Selector("swipeToInbox"), forControlEvents:UIControlEvents.TouchUpInside)
        let inboxButtonImage = UIImage(named: "inboxButtonImage")
        inboxButton.setImage(inboxButtonImage, forState: .Normal)
        inboxButton.alpha = 1
        view.addSubview(inboxButton)
        
        inboxButtonFill = UIButton(frame: CGRectMake(self.view.frame.width-(20+30),self.view.frame.height-60, 30, 30))
        inboxButtonFill.addTarget(self, action: Selector("swipeToInbox"), forControlEvents:UIControlEvents.TouchUpInside)
        let inboxButtonFillImage = UIImage(named: "inboxFillImage")
        inboxButtonFill.setImage(inboxButtonFillImage, forState: .Normal)
        inboxButtonFill.alpha = 0
        view.addSubview(inboxButtonFill)
        
        
    
    }
    
    
    func addFlipButton(){
        flipButton = UIButton(frame: CGRectMake(10, 20, 40, 40))
        flipButton.setTitle("😎", forState: .Normal)
        flipButton.setTitle("🌎", forState: .Selected)
        flipButton.titleLabel?.font = UIFont(name: "Arial-BoldMT", size: 32)
        flipButton.addTarget(self, action: Selector("toggleCamera:"), forControlEvents: .TouchUpInside)
        flipButton.titleLabel!.layer.shadowColor = UIColor.blackColor().CGColor
        flipButton.titleLabel!.layer.shadowOffset = CGSizeMake(0, 1)
        flipButton.titleLabel!.layer.shadowOpacity = 1
        flipButton.titleLabel!.layer.shadowRadius = 1
        view.addSubview(flipButton)
    }
    
    func toggleCamera(sender: UIButton) {
        
        if currentDeviceIsBack {
            var error:NSError?
            let possibleCameraInput: AnyObject? = AVCaptureDeviceInput.deviceInputWithDevice(frontCameraDevice, error: &error)
            if let frontCameraInput = possibleCameraInput as? AVCaptureDeviceInput {
                self.session.beginConfiguration()
                self.session.removeInput(currentInput)
                currentInput = frontCameraInput
                self.session.addInput(currentInput)
                self.session.commitConfiguration()
                currentDeviceIsBack = false
                sender.selected = !sender.selected
            }
            else {
                println("front camera not possible i guess?")
            }
        }
        else {
            var error:NSError?
            let possibleCameraInput: AnyObject? = AVCaptureDeviceInput.deviceInputWithDevice(backCameraDevice, error: &error)
            if let backCameraInput = possibleCameraInput as? AVCaptureDeviceInput {
                self.session.beginConfiguration()
                self.session.removeInput(currentInput)
                currentInput = backCameraInput
                self.session.addInput(currentInput)
                self.session.commitConfiguration()
                currentDeviceIsBack = true
                sender.selected = !sender.selected
            }
            else {
                println("back camera not possible i guess?")
            }
            
        }
        
    }
    
    func swipeToInbox(){
        let pvc = self.parentViewController as! UIPageViewController
        let ic = self.storyboard!.instantiateViewControllerWithIdentifier("InboxController") as! InboxController
        pvc.setViewControllers([ic], direction: .Forward, animated: true, completion: nil)
    }
    
    func addTextButton(){
        
        //TODO: - don't hardcode this

        let textButton = UIButton(frame: CGRect(x: 130, y: 20, width: 40, height: 40))
        textButton.center.x = self.view.center.x
        textButton.setImage(UIImage(named: "textButtonImage"), forState: .Normal)
        textButton.addTarget(self, action: Selector("toggleKeyboard:"), forControlEvents: .TouchUpInside)
        
        view.addSubview(textButton)
    }
    
    func toggleKeyboard(sender: UIButton){
        if textView.isFirstResponder() {
            textView.resignFirstResponder()
        }
        else {
            textView.becomeFirstResponder()
        }
        
    }
    
    func refreshCameraView(){
        
        self.previewLayer?.connection.enabled = true
        textView.text = ""
        textView.frame = CGRectMake(0,100,self.view.frame.width, 300)
        textView.frame.origin.y = self.view.frame.midY-100
        
        if pan != nil {
            textView.removeGestureRecognizer(pan!)
        }
    }
    
    func addTextView(){
        
        textView = UITextView(frame: CGRectMake(0,100,self.view.frame.width, 300))
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
        
        let placeholderText = NSAttributedString(string: " ", attributes: attr)
        textView.attributedText = placeholderText
        textView.textAlignment = .Center
        textView.text = ""
        textView.textContainerInset = UIEdgeInsets(top: 40, left: 0, bottom: 40, right: 0)
        
        //TODO: Maybe contentOffset is better here.
        
    //    textView.layer.borderColor = UIColor.redColor().CGColor
    //    textView.layer.borderWidth = 2.0
        textView.clipsToBounds = true
        textView.frame.origin.y = self.view.frame.midY-100
        textViewPosition = textView.center
        
        
        self.view.addSubview(textView)
        
    }
    
    func handleTextViewPan(sender: UIPanGestureRecognizer){
        let viewToPan = sender.view
        let translation = sender.translationInView(self.view)
        viewToPan!.center = CGPointMake(viewToPan!.center.x + translation.x, viewToPan!.center.y + translation.y)
        sender.setTranslation(CGPointZero, inView: self.view)
        println(textView.center)
        
        if sender.state == .Ended {
            self.textViewPosition = textView.center
        }

    }
    
    
    func l8rButtonTapped(sender: UITapGestureRecognizer){
        self.previewLayer?.connection.enabled = false
        self.takeScreenSnapshotFromGesture(sender)
    }
    
    func l8rButtonLongpressed(sender: UILongPressGestureRecognizer){
        if sender.state == .Began{
            self.previewLayer?.connection.enabled = false
            self.takeScreenSnapshotFromGesture(sender)
        }
    }
    
    func takeScreenSnapshotFromGesture(sender: AnyObject){
        dispatch_async(sessionQueue) { () -> Void in
            
            let connection = self.stillCameraOutput.connectionWithMediaType(AVMediaTypeVideo)
            connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIDevice.currentDevice().orientation.rawValue)!
            self.stillCameraOutput.captureStillImageAsynchronouslyFromConnection(connection) {
                (imageDataSampleBuffer, error) -> Void in
                
                if error == nil {
                    println("should be disabling connection...")
                    
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                    let metadata:NSDictionary = CMCopyDictionaryOfAttachments(nil, imageDataSampleBuffer, CMAttachmentMode(kCMAttachmentMode_ShouldPropagate)).takeUnretainedValue()

                    if let theImage = UIImage(data: imageData, scale: 1.0) {
                        
                        
//                        //stuff that has to do with saving the image
//                        
//                        let imageView = UIImageView(frame: CGRectMake(0, 0, theImage.size.width*self.view.frame.height/theImage.size.height, self.view.frame.height))
//                        imageView.contentMode = UIViewContentMode.ScaleToFill
//
//                        if !self.currentDeviceIsBack {
//                            imageView.image = UIImage(CGImage: theImage.CGImage, scale: theImage.scale, orientation: UIImageOrientation.LeftMirrored)
//                        }
//                        else {
//                            imageView.image = theImage
//                        }
//                        
//                        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, imageView.opaque, 0.0)
//                        imageView.drawViewHierarchyInRect(imageView.bounds, afterScreenUpdates: true)
//                        let snapshotImage = UIGraphicsGetImageFromCurrentImageContext()
//                        UIGraphicsEndImageContext()
//                        self.snapshotImage = snapshotImage
                        
                        //TODO: we shouldn't have to wait for the snapshot to bring up the l8r options
                    
                        if sender.isKindOfClass(UILongPressGestureRecognizer){
                            println("longpress")
                            self.showExtraL8rOptions()
                        }
                        else if sender.isKindOfClass(UITapGestureRecognizer){
                            println("tap")
                            
                            var scheduledDate: NSDate!
                            var theCalendar = NSCalendar.currentCalendar()
                            let currentTime = NSDate()
                        
                            
//                            //tomorrow at 9am
//                            let tomorrowComponent = NSDateComponents()
//                            tomorrowComponent.day = 1
//                            let tomorrow = theCalendar.dateByAddingComponents(tomorrowComponent, toDate: currentTime, options: NSCalendarOptions(0))
//                            let tomorrowAt9AmComponents = theCalendar.components(NSCalendarUnit.CalendarUnitCalendar|NSCalendarUnit.CalendarUnitYear|NSCalendarUnit.CalendarUnitMonth|NSCalendarUnit.CalendarUnitDay, fromDate: tomorrow!)
//                            tomorrowAt9AmComponents.hour = 9
//                            scheduledDate = theCalendar.dateFromComponents(tomorrowAt9AmComponents)
                            
                            
                            //in a minute (for testing)
                            let timeComponent = NSDateComponents()
                            timeComponent.second = 1
                            scheduledDate = theCalendar.dateByAddingComponents(timeComponent, toDate: currentTime, options: NSCalendarOptions(0))
                            
                            let position = self.textViewPosition
                        
                            self.saveL8rWithDate(scheduledDate, imageData:imageData, position:position)
                            
                            self.flashConfirm()

                            
                        }
                        
                        else if sender is UIButton {
                            println("Received from Date Picker")
                            
                            let scheduledDate = self.datePicker.date
                            let position = self.textViewPosition
                            self.saveL8rWithDate(scheduledDate, imageData:imageData, position:position)
                            let viewToDisappear = sender.superview!
                            viewToDisappear!.subviews.map({ $0.removeFromSuperview() })
                            viewToDisappear?.removeFromSuperview()
                            
                            self.flashConfirm()

                        }
                        
                        else {
                            println("kind of class is \(sender)")

                        }
                    }
                }
                    
                else {
                    NSLog("error while capturing still image: \(error)")
                }
            }
        }
    }
    
    func saveL8rWithDate(scheduledDate: NSDate, imageData: NSData, position: CGPoint){
        
        dispatch_async(dispatch_get_main_queue(), {   ()->Void in
            
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            self.managedContext = appDelegate.managedObjectContext!
            
            let entity = NSEntityDescription.entityForName("L8R", inManagedObjectContext: self.managedContext)
            
            let l8rItem:L8RItem = NSEntityDescription.insertNewObjectForEntityForName("L8RItem", inManagedObjectContext: self.managedContext) as! L8RItem
            //TODO: Does compression happen here?
            l8rItem.imageData = imageData
            l8rItem.dueDate = scheduledDate
            l8rItem.text = self.l8rText
            l8rItem.textPosition = NSStringFromCGPoint(position)
            self.l8rText = ""
            
            println(l8rItem)
            
            var error: NSError?
            if !self.managedContext.save(&error) {
                println("Coulnd't save \(error), \(error?.userInfo)")
            }
            self.scheduleLocalNotificationWithDueDate(scheduledDate)
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
    
    func showExtraL8rOptions(){
        
        extraL8rsContainerView = UIView(frame: self.view.frame)
        self.view.addSubview(extraL8rsContainerView)
        
        //var buttonImage = ["dateImage", "placeImage", "personImage"]
    
        for buttonImage in ["calendarImage"]{//, "placeImage", "personImage"]{
  
            let button = UIButton(frame: CGRectMake(self.view.frame.midX-42, self.view.frame.height, 85, 93))
            //button.setTitle(buttonTitle, forState: .Normal)
            button.setImage(UIImage(named: buttonImage), forState: UIControlState.Normal)
            button.titleLabel?.font = UIFont(name: "Arial-BoldMT", size: 32)
            button.addTarget(self, action: Selector("extraL8rPressed:"), forControlEvents: .TouchUpInside)
            button.titleLabel!.layer.shadowColor = UIColor.blackColor().CGColor
            button.titleLabel!.layer.shadowOffset = CGSizeMake(0, 1)
            button.titleLabel!.layer.shadowOpacity = 1
            button.titleLabel!.layer.shadowRadius = 1
            button.transform = CGAffineTransformMakeScale(0,0)
            button.alpha = 0
            button.tag = 2
            extraL8rsContainerView.addSubview(button)
            
            UIView.animateKeyframesWithDuration(0.3, delay: 0, options: nil, animations: { () -> Void in
                button.alpha = 1
                button.center = self.view.center
                button.transform = CGAffineTransformMakeScale(1.0,1.0)
            }, completion: nil)
        }
    }
    
    func hideExtraL8rOptions(){
        self.extraL8rsContainerView.subviews.map({ $0.removeFromSuperview() })
        extraL8rsContainerView.removeFromSuperview()
    }
    
    
    func flashConfirm(){
        let flashConfirm = UIImageView(frame: CGRect(x:0, y: 0, width: self.view.frame.width-100, height: self.view.frame.width-100))
        flashConfirm.center = self.view.center
        flashConfirm.image = UIImage(named: "flashConfirmImage")
        flashConfirm.contentMode = UIViewContentMode.ScaleAspectFit
        flashConfirm.alpha = 0
        self.view.addSubview(flashConfirm)
        
        UIView.animateKeyframesWithDuration(0.2, delay: 0.2, options: nil, animations: { () -> Void in
            flashConfirm.alpha = 1
          //  flashConfirm.frame = CGRectMake(self.view.frame.midX, self.view.frame.midY, 0, 0)
            }, completion: {finished in
                UIView.animateKeyframesWithDuration(0.2, delay: 0.2, options: nil, animations: { () -> Void in
                    flashConfirm.alpha = 0
                }, completion: nil)
                self.refreshCameraView()
        })
        

    }
    
    func extraL8rPressed(sender: UIButton){
        
        if sender.tag == 2 {
            self.showDatePicker()
        }
        
    }
    
    func showDatePicker(){
        
        var datePickerView = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
        datePickerView.frame = self.view.frame
        self.view.addSubview(datePickerView)
        
        datePicker = UIDatePicker(frame: self.view.frame)
        datePicker.center.y = self.view.center.y
        datePickerView.addSubview(datePicker)
        
        let confirmButton = UIButton(frame: CGRectMake(0, 200, 100, 100))
        confirmButton.center.x = self.view.center.x
        confirmButton.center.y = datePicker.frame.maxY+60
        confirmButton.setImage(UIImage(named: "inboxSnapButtonImage"), forState: .Normal)
        confirmButton.tag = 777
        confirmButton.addTarget(self, action: Selector("getDatePickerDate:"), forControlEvents: .TouchUpInside)
        datePickerView.addSubview(confirmButton)
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            
            //TODO: trying to resize text view. (need to think about container inset)
            l8rText = textView.text
            if pan != nil {
                textView.removeGestureRecognizer(pan!)
            }
            if !l8rText.isEmpty{
                let fixedWidth = textView.frame.size.width
                let newSize = textView.sizeThatFits(CGSizeMake(fixedWidth, CGFloat(MAXFLOAT)))
                var newFrame = textView.frame
                newFrame.size = CGSizeMake(CGFloat(fmaxf(Float(newSize.width), Float(fixedWidth))), newSize.height)
                textView.frame = newFrame
                
                pan = UIPanGestureRecognizer(target: self, action: Selector("handleTextViewPan:"))
                textView.addGestureRecognizer(pan!)
                
                println("new frame:\(textView.frame)")
            }
            else {
                textView.frame = self.view.frame
                textView.frame.origin.y = self.view.frame.midY-100
            }
            self.textViewPosition = textView.center
            println(self.textViewPosition)
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}