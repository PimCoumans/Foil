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
	weak var inputReceivingNode: Node? = nil
	
	override var handlesInput: Bool {
		// By default, all touch input events are captured by
		// the scene. If false is returned, the next node is searched
		return true
	}
	
	override var frame: CGRect {
		if let renderView = renderView {
			return renderView.screen.bounds
		}
		return .zero
	}
	
	func cancelInteraction() {
		touchCancelled()
	}
	
	func update() {
		// update, with... stuff?
	}
	
}
