//
//  ViewController.swift
//  FoilMac
//
//  Created by Pim Coumans on 29/12/16.
//  Copyright © 2016 pixelrock. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (view as? RenderView)?.scene = ExampleScene()
    }
}

