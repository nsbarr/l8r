//
//  ViewController.swift
//  l8r
//
//  Created by nick barr on 5/16/15.
//  Copyright (c) 2015 poemsio. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    var arrayOfInstantiators:NSArray = ["MagicController","CameraController","InboxController"]
    var pageIndex = 1
    var magicController: MagicController!
    var cameraController: CameraController!
    var inboxController: InboxController!
    
    //MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupNotificationSettings()
        self.createPageViewController()
        
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func createPageViewController(){
        
        magicController = self.storyboard!.instantiateViewControllerWithIdentifier("MagicController") as! MagicController
        cameraController = self.storyboard!.instantiateViewControllerWithIdentifier("CameraController") as! CameraController
        inboxController = self.storyboard!.instantiateViewControllerWithIdentifier("InboxController") as! InboxController
        
        
        let pageController = self.storyboard!.instantiateViewControllerWithIdentifier("PageController") as! UIPageViewController
        pageController.delegate = self
        pageController.dataSource = self
        
        let startingViewController = self.viewControllerAtIndex(self.pageIndex)
        
        let startingViewControllers = [startingViewController]
        

        pageController.addChildViewController(cameraController)
        self.view.addSubview(pageController.view)
        pageController.didMoveToParentViewController(self)
        
        self.addChildViewController(pageController)
        
                pageController.setViewControllers(startingViewControllers as [AnyObject], direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        
        println("looking fwd")

        let identifier = viewController.restorationIdentifier
        pageIndex = self.arrayOfInstantiators.indexOfObject(identifier!)
        
        if pageIndex == arrayOfInstantiators.count - 1 {
            
            return nil
        }
        
        else {
            pageIndex = pageIndex + 1
            return self.viewControllerAtIndex(self.pageIndex)
        }
        
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        
        println("looking back")
        
        let identifier = viewController.restorationIdentifier
        pageIndex = self.arrayOfInstantiators.indexOfObject(identifier!)
        
        if pageIndex == 0 {
            
            return nil
        }
            
        else {
            self.pageIndex = self.pageIndex - 1
            return self.viewControllerAtIndex(self.pageIndex)
        }
        
    }
    
    
    func viewControllerAtIndex(index: Int) -> UIViewController! {
        
        println("getting index \(index)")
        
        if index == 0 {
            return magicController
        }
        else if index == 1 {
            
            return cameraController

        }
        
        else if index == 2 {
            return inboxController
            
        }
            
        else {
        
            return nil
        }
    }
    
    func setupNotificationSettings() {
        
        
        //TODO: Unhack this
        UIApplication.sharedApplication().applicationIconBadgeNumber = 0
        
        let notificationSettings: UIUserNotificationSettings! = UIApplication.sharedApplication().currentUserNotificationSettings()
        
        if (notificationSettings.types == UIUserNotificationType.None){
            
            var notificationTypes: UIUserNotificationType = UIUserNotificationType.Alert | UIUserNotificationType.Badge
            
            var ignoreAction = UIMutableUserNotificationAction()
            ignoreAction.identifier = "ignore"
            ignoreAction.title = "Ignore"
            ignoreAction.activationMode = UIUserNotificationActivationMode.Background
            ignoreAction.destructive = false
            ignoreAction.authenticationRequired = false
            
            var viewAction = UIMutableUserNotificationAction()
            viewAction.identifier = "view"
            viewAction.title = "View"
            viewAction.activationMode = UIUserNotificationActivationMode.Foreground
            viewAction.destructive = false
            viewAction.authenticationRequired = true
            
            let actionsArray = NSArray(objects: ignoreAction, viewAction)
            
            var l8rReminderCategory = UIMutableUserNotificationCategory()
            l8rReminderCategory.identifier = "l8rReminderCategory"
            l8rReminderCategory.setActions(actionsArray as [AnyObject], forContext: UIUserNotificationActionContext.Default)
            l8rReminderCategory.setActions(actionsArray as [AnyObject], forContext: UIUserNotificationActionContext.Minimal)
            
            
            let categoriesForSettings = NSSet(objects: l8rReminderCategory)
            
            
            let newNotificationSettings = UIUserNotificationSettings(forTypes: notificationTypes, categories: categoriesForSettings as Set<NSObject>)
            
            UIApplication.sharedApplication().registerUserNotificationSettings(newNotificationSettings)
        }
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

