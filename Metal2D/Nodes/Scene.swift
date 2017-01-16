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
	var renderInZOrder: Bool = false
	
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
	
	override func renderRecursively(with context: RenderContext) {
		if !renderInZOrder {
			super.renderRecursively(with: context)
			return
		}
		// TODO: cache references to ordered nodes?
		var nodes = [Node]()
		func addNodesFromNode(node:Node) {
			guard !node.hidden else { return }
			for child in node.children {
				guard !child.hidden else { continue }
				if child.children.count == 0 {
					nodes.append(child)
				} else {
					addNodesFromNode(node: child)
				}
			}
		}
		addNodesFromNode(node: self)
		nodes.sort(by: {$0.globalZPosition < $1.globalZPosition})
		for node in nodes {
			node.render(with: context)
		}
	}
	
	func willMoveToRenderView(renderView:RenderView?) {}
	func didMoveToRenderView() {}
	
}
