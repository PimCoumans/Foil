//
//  Scene.swift
//  Metal2D
//
//  Created by Pim Coumans on 25/11/16.
//  Copyright © 2016 pixelrock. All rights reserved.
//

import Foundation
import CoreGraphics

class Scene: Node {
	
	weak var renderView: RenderView? {
		willSet {
			willMoveToRenderView(renderView: newValue)
		}
		didSet {
			didMoveToRenderView()
		}
	}
	
	weak var inputReceivingNode: Node? = nil
	
	override var handlesInput: Bool {
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
	
	func update(withContext context:RenderContext) {
		// update, with... stuff?
	}
	
	func willMoveToRenderView(renderView:RenderView?) {}
	func didMoveToRenderView() {}
	
}
