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



class CameraController: UIViewController, UIGestureRecognizerDelegate {
    
    //camera setup
    var previewLayer : AVCaptureVideoPreviewLayer?
    var backCameraDevice:AVCaptureDevice?
    var frontCameraDevice:AVCaptureDevice?
    var stillCameraOutput:AVCaptureStillImageOutput!
    let session = AVCaptureSession()
    var currentInput: AVCaptureDeviceInput?
    var currentDeviceIsBack = true
    var sessionQueue = dispatch_queue_create("com.example.camera.capture_session", DISPATCH_QUEUE_SERIAL)

    //button setup
    var snapButton:UIButton!
    
    
    //image setup
    var snapshotImage: UIImage!
    
    //coreData setup
    var managedContext: NSManagedObjectContext!




    
    
    override func viewDidLoad() {
        println("camera")
        self.setUpCamera()
        self.addSnapButton()
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
    
    func takeScreenSnapshotFromGesture(sender: UIGestureRecognizer){
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
                        
                        let imageView = UIImageView(frame: CGRectMake(0, 0, theImage.size.width*self.view.frame.height/theImage.size.height, self.view.frame.height))
                        imageView.contentMode = UIViewContentMode.ScaleToFill

                        if !self.currentDeviceIsBack {
                            imageView.image = UIImage(CGImage: theImage.CGImage, scale: theImage.scale, orientation: UIImageOrientation.LeftMirrored)
                        }
                        else {
                            imageView.image = theImage
                        }
                        
//                        self.textView.frame.origin.x = self.textView.frame.origin.x + (imageView.frame.width-self.view.frame.width)/2
//                        imageView.addSubview(self.textView)
                        
                        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, imageView.opaque, 0.0)
                        imageView.drawViewHierarchyInRect(imageView.bounds, afterScreenUpdates: true)
                        let snapshotImage = UIGraphicsGetImageFromCurrentImageContext()
                        UIGraphicsEndImageContext()
                        self.snapshotImage = snapshotImage
                        
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
                            let tomorrowComponent = NSDateComponents()
                            tomorrowComponent.day = 1
                            let tomorrow = theCalendar.dateByAddingComponents(tomorrowComponent, toDate: currentTime, options: NSCalendarOptions(0))
                            let tomorrowAt9AmComponents = theCalendar.components(NSCalendarUnit.CalendarUnitCalendar|NSCalendarUnit.CalendarUnitYear|NSCalendarUnit.CalendarUnitMonth|NSCalendarUnit.CalendarUnitDay, fromDate: tomorrow!)
                            tomorrowAt9AmComponents.hour = 9
                            scheduledDate = theCalendar.dateFromComponents(tomorrowAt9AmComponents)
                        
                            self.saveL8rWithDate(scheduledDate, imageData:imageData)

                            self.flashConfirm()
                            self.previewLayer?.connection.enabled = true
                     //       self.addTextView()
                            
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
    
    func saveL8rWithDate(scheduledDate: NSDate, imageData: NSData){
        
        dispatch_async(dispatch_get_main_queue(), {   ()->Void in
            
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            self.managedContext = appDelegate.managedObjectContext!
            
            let entity = NSEntityDescription.entityForName("L8R", inManagedObjectContext: self.managedContext)
            
            let l8rItem:L8RItem = NSEntityDescription.insertNewObjectForEntityForName("L8R", inManagedObjectContext: self.managedContext) as! L8RItem
     //       let imageData = UIImageJPEGRepresentation(self.image, 0.8) //0 is most compression
            l8rItem.imageData = imageData
            l8rItem.dueDate = scheduledDate
            
            var error: NSError?
            if !self.managedContext.save(&error) {
                println("Coulnd't save \(error), \(error?.userInfo)")
            }
//            vc.scheduleLocalNotificationWithFireDate(scheduledDate)
            
        })
        
    }
    
    func flashConfirm(){
        let flashConfirm = UIImageView(frame: CGRect(x:0, y: 0, width: self.view.frame.width-100, height: self.view.frame.width-100))
        flashConfirm.center = self.view.center
        flashConfirm.image = UIImage(named: "altFlashConfirm")
        flashConfirm.contentMode = UIViewContentMode.ScaleAspectFit
        flashConfirm.alpha = 1
        self.view.addSubview(flashConfirm)
        
        UIView.animateKeyframesWithDuration(0.5, delay: 0.3, options: nil, animations: { () -> Void in
            flashConfirm.alpha = 0
            flashConfirm.frame = CGRectMake(self.view.frame.midX, self.view.frame.midY, 0, 0)
            }, completion: nil)
        
    }




    

}