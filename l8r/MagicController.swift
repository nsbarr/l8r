//
//  MagicController.swift
//  l8r
//
//  Created by nick barr on 5/16/15.
//  Copyright (c) 2015 poemsio. All rights reserved.
//

import Foundation
import UIKit
import WebKit

class MagicController: UIViewController {
    
    
    
    override func viewDidLoad() {
        println("magic")
        
        var wkWebView = WKWebView(frame: CGRect(x:0.0, y:0.0, width:self.view.frame.width, height:self.view.frame.height-0.0))
        
        let url = "http://www.nsbarr.com/l8r"
        let nsurl = NSURL(string: url)
        let nsrequest = NSURLRequest(URL: nsurl!)
        wkWebView.loadRequest(nsrequest)
        self.view.addSubview(wkWebView)
    }
    
}