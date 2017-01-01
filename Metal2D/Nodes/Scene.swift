//
//  Scene.swift
//  Metal2D
//
//  Created by Pim Coumans on 25/11/16.
//  Copyright © 2016 pixelrock. All rights reserved.
//

import Foundation

class Scene: Node {
	
	weak var renderView: RenderView?
	
	override var handlesInput: Bool {
		return true
	}
	
	func cancelInteraction() {
		touchCancelled()
	}
	
	func update() {
		// update, with... stuff?
	}
	
}
