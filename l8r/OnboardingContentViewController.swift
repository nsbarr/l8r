//
//  OnboardingContentViewController.swift
//  l8r
//
//  Created by nick barr on 6/2/15.
//  Copyright (c) 2015 poemsio. All rights reserved.
//

import Foundation
import UIKit

class OnboardingContentViewController: UIViewController {
    let kDefaultOnboardingFont: String = "AvenirNextCondensed-Regular"
    let kDefaultTextColor: UIColor = UIColor(red: 77/255, green: 77/255, blue: 77/255, alpha: 1)
    let kContentWidthMultiplier: CGFloat = 0.9
    let kDefaultImageViewSize: CGFloat = 100
    let kDefaultTopPadding: CGFloat = 100
    let kDefaultUnderIconPadding: CGFloat = 30
    let kDefaultUnderTitlePadding: CGFloat = 30
    let kDefaultBottomPadding: CGFloat = 10
    let kDefaultTitleFontSize: CGFloat = 32
    let kDefaultBodyFontSize: CGFloat = 22
    let kDefaultActionButtonHeight: CGFloat = 50
    let kDefaultMainPageControlHeight: CGFloat = 35
    let titleText: String
    let body: String
    let image: UIImage
    let bgColor: UIColor
    let buttonText: String
    let action: dispatch_block_t?
    
    var iconSize: CGFloat
    var fontName: String
    var titleFontSize: CGFloat
    var bodyFontSize: CGFloat
    var topPadding: CGFloat
    var underIconPadding: CGFloat
    var underTitlePadding: CGFloat
    var bottomPadding: CGFloat
    var titleTextColor: UIColor
    var bodyTextColor: UIColor
    var buttonTextColor: UIColor
    
    
    init(title: String?, body: String?, image: UIImage?, buttonText: String?, bgColor: UIColor?, action: dispatch_block_t?) {
        // setup the optional initializer parameters if they were passed in or not
        self.titleText = title != nil ? title! : String()
        self.body = body != nil ? body! : String()
        self.bgColor = bgColor != nil ? bgColor! : UIColor()
        self.image = image != nil ? image! : UIImage()
        self.buttonText = buttonText != nil ? buttonText! : String()
        self.action = action != nil ? action : {}
        
        // setup the initial default properties
        self.iconSize = kDefaultImageViewSize;
        self.fontName = kDefaultOnboardingFont;
        self.titleFontSize = kDefaultTitleFontSize;
        self.bodyFontSize = kDefaultBodyFontSize;
        self.topPadding = kDefaultTopPadding;
        self.underIconPadding = kDefaultUnderIconPadding;
        self.underTitlePadding = kDefaultUnderTitlePadding;
        self.bottomPadding = kDefaultBottomPadding;
        self.titleTextColor = kDefaultTextColor;
        self.bodyTextColor = kDefaultTextColor;
        self.buttonTextColor = kDefaultTextColor;
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        generateView()
    }
    
    func generateView() {
        // the background of each content page will be clear to be able to
        // see through to the background image of the master view controller
        self.view.backgroundColor = self.bgColor
        
        // do some calculation for some values we'll need to reuse, namely the width of the view,
        // the center of the width, and the content width we want to fill up, which is some
        // fraction of the view width we set in the multipler constant
        let viewWidth: CGFloat = CGRectGetWidth(self.view.frame)
        let horizontalCenter: CGFloat = viewWidth / 2
        let contentWidth: CGFloat = viewWidth * kContentWidthMultiplier
        
        // create the image view with the appropriate image, size, and center in on screen
        var imageView: UIImageView = UIImageView(image: self.image)
        imageView.frame = self.view.frame
        self.view.addSubview(imageView)
        imageView.contentMode = UIViewContentMode.ScaleAspectFill
        
        var titleLabel: UILabel = UILabel(frame: CGRectMake(0, self.topPadding, contentWidth, 0))
        titleLabel.text = self.titleText
        titleLabel.font = UIFont(name: self.fontName, size: self.titleFontSize)
        titleLabel.textColor = self.titleTextColor
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .Center
        titleLabel.sizeToFit()
        titleLabel.center = CGPointMake(horizontalCenter, titleLabel.center.y)
        self.view.addSubview(titleLabel)
        
        var bodyLabel: UILabel = UILabel(frame: CGRectMake(0, CGRectGetMaxY(titleLabel.frame) + self.underTitlePadding, contentWidth, 0))
        bodyLabel.text = self.body
        bodyLabel.font = UIFont(name: self.fontName, size: self.bodyFontSize)
        bodyLabel.textColor = self.titleTextColor
        bodyLabel.numberOfLines = 0
        bodyLabel.textAlignment = .Center
        bodyLabel.sizeToFit()
        bodyLabel.center = CGPointMake(horizontalCenter, bodyLabel.center.y)
        self.view.addSubview(bodyLabel)
        
        if (count(self.buttonText) != 0) {
            var actionButton: UIButton = UIButton(frame: CGRectMake((CGRectGetMaxX(self.view.frame) / 2) - (contentWidth / 2), CGRectGetMaxY(self.view.frame) - kDefaultMainPageControlHeight - kDefaultActionButtonHeight - self.bottomPadding, contentWidth, kDefaultActionButtonHeight))
            actionButton.titleLabel?.font = UIFont(name: "Dosis-Bold", size: 32.0)!
            actionButton.setTitle(self.buttonText, forState: .Normal)
            actionButton.setTitleColor(self.buttonTextColor, forState: .Normal)
            actionButton.addTarget(self, action: "handleButtonPressed", forControlEvents: .TouchUpInside)
            actionButton.layer.borderWidth = 2.0
            actionButton.layer.borderColor = self.buttonTextColor.CGColor
            actionButton.layer.cornerRadius = 8.0
            actionButton.sizeToFit()
            actionButton.center.x = self.view.center.x
            self.view.addSubview(actionButton)
        }
    }
    
    func handleButtonPressed() {
        println("foo")
        self.action!()
    }
    
}
