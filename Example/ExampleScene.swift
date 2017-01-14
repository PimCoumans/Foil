//
//  ExampleScene.swift
//  Metal2D
//
//  Created by Pim Coumans on 30/12/16.
//  Copyright © 2016 pixelrock. All rights reserved.
//

#if os(iOS)
	import UIKit
#elseif os(OSX)
	import Cocoa
#endif

class ExampleScene: Scene {
	var textureNode:TextureNode!
	var lineNode:LineNode!
	
	override func didMoveToRenderView() {
		guard let renderView = renderView else { return }
		#if os(iOS)
			let image = UIImage(named:"pim")
		#elseif os(OSX)
			let image = NSImage(named:"pim")
			
		#endif
		renderView.screen.zoomScale = 60
		
		let rootNode = Node()
		rootNode.position = CGPoint(x:30, y:30)
		rootNode.scale = CGSize(width: 10, height: 10)
		addChild(rootNode)
		
		if let image = image, let textureNode = TextureNode(image: image, size:CGSize(width:2, height:2)) {
			self.textureNode = textureNode
			rootNode.addChild(textureNode)
		}
		
		lineNode = LineNode()
		rootNode.addChild(lineNode)
	}
	
	var moveDirection = CGPoint(x: 1, y: 1)
	override func update(withContext context:RenderContext) {
		guard let renderView = renderView, let rootNode = children.first, selectedChildNode == nil else { return }
		
		var textureNodePosition = textureNode.globalPosition
		textureNodePosition += (moveDirection * CGFloat(60 * context.delta))
		let convertedPosition = rootNode.convert(worldPosition: textureNodePosition)
		textureNode.position = convertedPosition
		
		var cappedPosition = textureNode.globalPosition
		let boundingRect = textureNode.globalFrame
		let screenbounds = renderView.screen.bounds
		if boundingRect.maxX >= screenbounds.maxX {
			cappedPosition.x = screenbounds.maxX - (boundingRect.width / 2)
			moveDirection.x = 0 - moveDirection.x
		}
		else if boundingRect.minX <= screenbounds.minX {
			cappedPosition.x = screenbounds.minX + (boundingRect.width / 2)
			moveDirection.x = 0 - moveDirection.x
		}
		
		if boundingRect.maxY >= screenbounds.maxY {
			cappedPosition.y = screenbounds.maxY - (boundingRect.height / 2)
			moveDirection.y = 0 - moveDirection.y
		}
		else if boundingRect.minY <= screenbounds.minY {
			cappedPosition.y = screenbounds.minY + (boundingRect.height / 2)
			moveDirection.y = 0 - moveDirection.y
		}
		
		if cappedPosition != textureNodePosition {
			textureNode.position = rootNode.convert(worldPosition: cappedPosition)
		}
		lineNode.points[1] = textureNode.position
	}
	
	override func touchBegan(atPosition position: CGPoint) {
		if let node = self.node(atPosition: position) {
			selectedChildNode = node
		}
	}
	
	override func touchMoved(toPosition position: CGPoint, delta: CGPoint) {
		if let node = selectedChildNode, let parent = node.parent {
			node.position = parent.convert(worldPosition: position)
			lineNode.points[1] = textureNode.position
		}
	}
	
	override func touchEnded(atPosition position: CGPoint, delta: CGPoint) {
		if let _ = selectedChildNode {
			selectedChildNode = nil
			moveDirection = delta
		}
	}
	
	override func touchCancelled() {
		selectedChildNode = nil
	}
}
