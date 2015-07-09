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



class CameraController: UIViewController, UIGestureRecognizerDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
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
    var questionButton: UIButton!
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
    
    //onboarding setup
    let userHasTakenL8rKey = "user_has_taken_l8r"



    
    //image setup


    //MARK: - View Lifecycle
    
    override func viewDidLoad() {
        println("camera")
        self.setUpCamera()
        self.addTextView()
        self.addTextButton()
        self.addQuestionButton()
        self.addFlipButton()
        self.addSnapButton()
        self.addImagePickerButton()
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
        inboxButton.addTarget(self, action: Selector("swipeToInbox:"), forControlEvents:UIControlEvents.TouchUpInside)
        let inboxButtonImage = UIImage(named: "inboxButtonImage")
        inboxButton.setImage(inboxButtonImage, forState: .Normal)
        inboxButton.alpha = 1
        inboxButton.tag = 3
        view.addSubview(inboxButton)
        
        inboxButtonFill = UIButton(frame: CGRectMake(self.view.frame.width-(20+30),self.view.frame.height-60, 30, 30))
        inboxButtonFill.addTarget(self, action: Selector("swipeToInbox:"), forControlEvents:UIControlEvents.TouchUpInside)
        let inboxButtonFillImage = UIImage(named: "inboxFillImage")
        inboxButtonFill.setImage(inboxButtonFillImage, forState: .Normal)
        inboxButtonFill.alpha = 0
        inboxButtonFill.tag = 3
        view.addSubview(inboxButtonFill)
    
    }
    
    func addImagePickerButton(){
        var imagePickerButton = UIButton(frame: CGRect(x: self.view.frame.width-100, y: 20, width: 40, height: 40))
        imagePickerButton.setTitle("Ok", forState: .Normal)
        //imagePickerButton.setImage(UIImage(named: "imageGalleryButton"), forState: .Normal)
        imagePickerButton.addTarget(self, action: Selector("imagePickerButtonPressed:"), forControlEvents: .TouchUpInside)
        imagePickerButton.enabled = true // doesn't work yet
        imagePickerButton.alpha = 1
        imagePickerButton.tag = 101
       // view.addSubview(imagePickerButton)
    }
    
    func imagePickerButtonPressed(sender: UIButton){
        let imagePicker = UIImagePickerController()
        
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.SavedPhotosAlbum
        imagePicker.allowsEditing = false
        
        self.presentViewController(imagePicker, animated: true,
            completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func addQuestionButton(){
        
        //TODO: - don't hardcode this
        
        questionButton = UIButton(frame: CGRectMake(20,self.view.frame.height-60, 30, 30))
        questionButton.addTarget(self, action: Selector("swipeToInbox:"), forControlEvents:UIControlEvents.TouchUpInside)
        let inboxButtonImage = UIImage(named: "questionButtonImage")
        questionButton.setImage(inboxButtonImage, forState: .Normal)
        questionButton.alpha = 1
        questionButton.tag = 1
       // view.addSubview(questionButton)
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
    
    func swipeToInbox(sender: UIButton){
        let pvc = self.parentViewController as! UIPageViewController
        let ic = self.storyboard!.instantiateViewControllerWithIdentifier("InboxController") as! InboxController
        let mc = self.storyboard!.instantiateViewControllerWithIdentifier("MagicController") as! MagicController
        
        if sender.tag == 3 {
        
            pvc.setViewControllers([ic], direction: .Forward, animated: true, completion: nil)
        }
        else if sender.tag == 1 {
            pvc.setViewControllers([mc], direction: .Reverse, animated: true, completion: nil)

        }
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
    
    
    func getImageRecognition(imageData: NSData){
        var url = NSURL(string: "http://earlspeaks.ngrok.com/api/image_to_labels")
        var request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "POST"
        let encodedData = NSData(base64EncodedData: imageData, options: nil)
        request.HTTPBody = imageData
        
        var response: NSURLResponse? = nil
        var error: NSError? = nil
        let reply = NSURLConnection.sendSynchronousRequest(request, returningResponse:&response, error:&error)
        
        let results = NSString(data:reply!, encoding:NSUTF8StringEncoding)
        println("API Response: \(results)")
    }
    
    func justNoodlin(imageData: NSData){
        

        var base64String = imageData.base64EncodedStringWithOptions(.allZeros)
        
        base64String = base64String.stringByReplacingOccurrencesOfString("+", withString: "%2B")

      //  let dictionary = ["api_key" : "mfVi4AaGEjlrLN13", "api_secret" : "qvR0IUUrxqbdF6FS", "jobs" : "scene", "base64" : base64String]
        
        let dictionary = ["api_key" : "mfVi4AaGEjlrLN13", "api_secret" : "qvR0IUUrxqbdF6FS", "jobs" : "scene_understanding_3", "urls" : "http://rekognition.com/static/img/beach.jpg"]
        
        
       // let fooDict = dictionary.description.dataUsingEncoding(NSUTF8StringEncoding)
       let fooDict = NSKeyedArchiver.archivedDataWithRootObject(dictionary)

        var url = NSURL(string:"http://rekognition.com/func/api/")
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "POST"
        request.HTTPBody = fooDict
        
        var response: NSURLResponse? = nil
        var error: NSError? = nil
        let reply = NSURLConnection.sendSynchronousRequest(request, returningResponse:&response, error:&error)
        
        let results = NSString(data:reply!, encoding:NSUTF8StringEncoding)
        println("API Response: \(results)")
        
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
        
        // Determine if the user has completed onboarding yet or not
        var userHasOnboardedAlready = NSUserDefaults.standardUserDefaults().boolForKey(userHasTakenL8rKey)
        
        // If the user has already onboarded, setup the normal root view controller for the application
        // without animation like you normally would if you weren't doing any onboarding
        if userHasOnboardedAlready {
            
        }
            
            // Otherwise the user hasn't onboarded yet, so set the root view controller for the application to the
            // onboarding view controller generated and returned by this method.
        else {
            self.presentViewController(self.generateOnboardingViewController(), animated: true, completion: nil)
        }
        
    }
    
    func generateOnboardingViewController() -> OnboardingContentViewController {
        
        let greenBg = UIColor(red: 129/255, green: 230/255, blue: 213/255, alpha: 1)

        let thirdPage: OnboardingContentViewController = OnboardingContentViewController(title: "Your first l8r!", body: "Yup, it’s that easy. I'll nudge you about your l8rs tomorrow, or whenever I finish tanning.", image: UIImage(named:
            "cameraTutImage"), buttonText: "  Got it  ", bgColor: greenBg) {
                self.handleOnboardingCompletion()
        }
        return thirdPage
    }
    
    func l8rButtonLongpressed(sender: UILongPressGestureRecognizer){
        if sender.state == .Began{
            self.previewLayer?.connection.enabled = false
            self.takeScreenSnapshotFromGesture(sender)
        }
    }
    
    func handleOnboardingCompletion(){
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: userHasTakenL8rKey)
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    

    
    func takeScreenSnapshotFromGesture(sender: AnyObject){
        
        if sender.isKindOfClass(UITapGestureRecognizer){
        
            let darkView = UIView(frame: self.view.frame)
            darkView.backgroundColor = UIColor.blackColor()
            self.view.addSubview(darkView)
            
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                darkView.alpha = 0
                }) { (Bool) -> Void in
                    darkView.removeFromSuperview()
            }
        }
        
        dispatch_async(sessionQueue) { () -> Void in
            
            let connection = self.stillCameraOutput.connectionWithMediaType(AVMediaTypeVideo)
            connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIDevice.currentDevice().orientation.rawValue)!
            self.stillCameraOutput.captureStillImageAsynchronouslyFromConnection(connection) {
                (imageDataSampleBuffer, error) -> Void in
                
                if error == nil {
                    println("should be disabling connection...")
                    
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                    let metadata:NSDictionary = CMCopyDictionaryOfAttachments(nil, imageDataSampleBuffer, CMAttachmentMode(kCMAttachmentMode_ShouldPropagate)).takeUnretainedValue()

                    if var theImage = UIImage(data: imageData, scale: 1.0) {
                        
                        //TODO: mirror selfies

                        if sender.isKindOfClass(UILongPressGestureRecognizer){
                            println("longpress")
                            self.showExtraL8rOptions()
                        }
                        else if sender.isKindOfClass(UITapGestureRecognizer){
                            self.confirmWithImage(theImage)
                            var scheduledDate: NSDate!
                            var theCalendar = NSCalendar.currentCalendar()
                            let currentTime = NSDate()
                        
                            
                            //tomorrow at 9am
                            let tomorrowComponent = NSDateComponents()
                            tomorrowComponent.day = 1
                            let tomorrow = theCalendar.dateByAddingComponents(tomorrowComponent, toDate: currentTime, options: NSCalendarOptions(0))
                            let tomorrowAt9AmComponents = theCalendar.components(NSCalendarUnit.CalendarUnitCalendar|NSCalendarUnit.CalendarUnitYear|NSCalendarUnit.CalendarUnitMonth|NSCalendarUnit.CalendarUnitDay, fromDate: tomorrow!)
                            tomorrowAt9AmComponents.hour = 9
                            scheduledDate = theCalendar.dateFromComponents(tomorrowAt9AmComponents)
                            
                            
//                            //TODO: in a minute (for testing)
//                            let timeComponent = NSDateComponents()
//                            timeComponent.second = 1
//                            scheduledDate = theCalendar.dateByAddingComponents(timeComponent, toDate: currentTime, options: NSCalendarOptions(0))
                            
                            
                            let position = self.textViewPosition
                           // self.flashConfirm()
                            
                            self.saveL8rWithDate(scheduledDate, imageData:imageData, position:position)
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
    
    func confirmWithImage(savedImage: UIImage){
        self.refreshCameraView()
        
        let flashConfirm = UIImageView(frame: self.view.frame)
        flashConfirm.center = self.view.center
        flashConfirm.image = savedImage
        flashConfirm.contentMode = UIViewContentMode.ScaleAspectFill
        flashConfirm.alpha = 1
        self.view.addSubview(flashConfirm)
        
        
        UIView.animateWithDuration(1.0, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveEaseIn,
            animations: { () -> Void in
                flashConfirm.alpha = 0
                flashConfirm.center = CGPoint(x: flashConfirm.center.x, y: -(flashConfirm.frame.height))
                
            }, completion: {finished in
                flashConfirm.removeFromSuperview()
        })
        
//        UIView.animateKeyframesWithDuration(1.0, delay: 0, options: nil, animations: { () -> Void in
//            flashConfirm.alpha = 1
//            flashConfirm.frame = CGRectMake(self.view.frame.maxX, self.view.frame.maxY, 0, 0)
//            }, completion: {finished in
//                UIView.animateKeyframesWithDuration(0.2, delay: 0.2, options: nil, animations: { () -> Void in
//                    flashConfirm.alpha = 0
//                    }, completion: {finished in
//                        flashConfirm.removeFromSuperview()
//                })
//                
//        })
        
    }
    
    func saveL8rWithDate(scheduledDate: NSDate, imageData: NSData, position: CGPoint){
        
        dispatch_async(dispatch_get_main_queue(), {   ()->Void in
            
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            self.managedContext = appDelegate.managedObjectContext!
            
            let entity = NSEntityDescription.entityForName("L8R", inManagedObjectContext: self.managedContext)
            
            let l8rItem:L8RItem = NSEntityDescription.insertNewObjectForEntityForName("L8RItem", inManagedObjectContext: self.managedContext) as! L8RItem
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
          //  self.justNoodlin(imageData)
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
                    }, completion: {finished in
                        flashConfirm.removeFromSuperview()
                })
                self.refreshCameraView()
        })
        

    }
    
    func extraL8rPressed(sender: UIButton){
        
        if sender.tag == 2 {
            self.hideExtraL8rOptions()
            self.showDatePicker()
        }
        
    }
    
    func showDatePicker(){
        
        var datePickerView = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
        datePickerView.frame = self.view.frame
        self.view.addSubview(datePickerView)
        
        datePicker = UIDatePicker(frame: self.view.frame)
        datePicker.minuteInterval = 30
        datePicker.center.y = self.view.center.y
        datePickerView.addSubview(datePicker)
        
        let confirmButton = UIButton(frame: CGRectMake(0, 200, 100, 100))
        confirmButton.center.x = self.view.center.x
        confirmButton.center.y = datePicker.frame.maxY+60
        confirmButton.setImage(UIImage(named: "inboxSnapButtonImage"), forState: .Normal)
        confirmButton.tag = 777
        confirmButton.addTarget(self, action: Selector("takeScreenSnapshotFromGesture:"), forControlEvents: .TouchUpInside)
        datePickerView.addSubview(confirmButton)
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            
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