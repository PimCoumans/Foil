//
//  GameViewController.swift
//  Metal2D
//
//  Created by Pim Coumans on 25/11/16.
//  Copyright © 2016 pixelrock. All rights reserved.
//

import UIKit

class GameViewController:UIViewController {
    
    override func viewDidLoad() {
        (view as? RenderView)?.scene = ExampleScene()
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
	
	override var prefersStatusBarHidden: Bool {
		return true
	}
    
}
