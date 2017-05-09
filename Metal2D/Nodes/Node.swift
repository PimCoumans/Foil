//
//  Node.swift
//  Metal2D
//
//  Created by Pim Coumans on 25/11/16.
//  Copyright © 2016 pixelrock. All rights reserved.
//

import Foundation
import QuartzCore
import GLKit
import MetalKit

class Node: Interactable, Animatable {
	
	// MARK: Geometry
	// Position and scale are based on the parents local coordinate system
	// If the parent has a scale of 2, this node has a scale of 1
	// it will be rendered twice as big
	var position = CGPoint.zero
	var zPosition: CGFloat = 0
	var anchorPoint = CGPoint(x: 0.5, y: 0.5)
	var scale = CGSize(width: 1, height: 1)
	var frame: CGRect {
		var frame = bounds
		frame.origin += position
		return frame.applying(transform)
	}
	
	var bounds: CGRect {
		return CGRect(origin: .zero, size: .zero)
	}
	
	// MARK: Hierarchy
	fileprivate(set) var scene:Scene? {
		willSet {
			willMoveToScene(newValue)
		}
		didSet {
			didMoveToScene()
			for node in children {
				node.scene = scene
			}
		}
	}
	fileprivate(set) weak var parent:Node? {
		willSet { willMoveToParent(newValue) }
		didSet { didMoveToParent() }
	}
	fileprivate(set) var children = [Node]()
	
	let uid:Int
	init() {
		uid = Node.nextUid()
	}
	
	func addChild(_ node:Node) {
		assert(!children.contains(node))
		children.append(node)
		node.parent = self
		if let scene = self as? Scene {
			node.scene = scene
		} else {
			node.scene = scene
		}
	}
	
	func removeFromParent() {
		guard let parent = parent,
			let index = parent.children.index(of: self) else {
				return
		}
		parent.children.remove(at: index)
		self.parent = nil
		self.scene = nil
	}
	
	// MARK: Updates
	func willMoveToParent(_ parent:Node?) {}
	func didMoveToParent() {}
	func willMoveToScene(_ scene:Scene?) {}
	func didMoveToScene() {}
	
	// MARK: Rendering
	func render(with context:RenderContext) {
		
	}
	
	func renderRecursively(with context:RenderContext) {
		guard !hidden else { return }
		render(with: context)
		for node in children {
			node.renderRecursively(with:context)
		}
	}
	
	// MARK: OpenGL Rendering
	func glRender(with context: RenderContext) {
		
	}
	
	func glRenderRecursively(with context: RenderContext) {
		guard !hidden else { return }
		glRender(with: context)
		for node in children {
			node.glRenderRecursively(with: context)
		}
	}
	
	// MARK: Interactable
	var handlesInput: Bool { return false }
	
	var enabled: Bool = true
	var hidden: Bool = false
	var highlighted: Bool = false
	var selected: Bool = false
	
	var alpha: CGFloat = 1
	var rotation: CGFloat = 0
	var transform: CGAffineTransform {
		let boundingRect = globalFrame
		var center = boundingRect.origin
		center.x += boundingRect.width * anchorPoint.x
		center.y += boundingRect.height * -anchorPoint.y
		
		return CGAffineTransform(translationX: center.x, y: center.y)
			.rotated(by: rotation)
			.translatedBy(x: -center.x, y: -center.y)
	}
	
	var highlightedChildNode: Node? = nil
	var selectedChildNode: Node? = nil
	
	func canHandleTouch(atPosition position: CGPoint) -> Bool {
		return true
	}
	func touchBegan(atPosition position: CGPoint) {}
	func touchMoved(toPosition position: CGPoint, delta: CGPoint) {}
	func touchEnded(atPosition position: CGPoint, delta: CGPoint) {}
	func touchCancelled() {}
	
	// MARK: - Animatable
	func set<T:Lerpable>(_ property: Property, value: T) {
		switch property {
		case Property.position:
			position = value as? CGPoint ?? position
		case Property.positionX:
			position.x = value as? CGFloat ?? position.x
		case Property.positionY:
			position.y = value as? CGFloat ?? position.y
		case Property.scale:
			scale = value as? CGSize ?? scale
		case Property.scaleWidth:
			scale.width = value as? CGFloat ?? scale.width
		case Property.scaleHeight:
			scale.height = value as? CGFloat ?? scale.height
		case Property.rotation:
			rotation = value as? CGFloat ?? rotation
		case Property.relativeRotation:
			rotation = value as? CGFloat ?? rotation
		default: break
		}
	}
	
	func get<T:Lerpable>(_ property: Property) -> T? {
		switch property {
		case Property.position:
			return position as? T
		case Property.positionX:
			return position.x as? T
		case Property.positionY:
			return position.y as? T
		case Property.scale:
			return scale as? T
		case Property.scaleWidth:
			return scale.width as? T
		case Property.scaleHeight:
			return scale.height as? T
		case Property.rotation, Property.relativeRotation:
			return rotation as? T
		default:
			return nil
		}
	}
}

extension Node: Hashable {
	
	fileprivate static var uid = 1
	fileprivate static func nextUid() -> Int {
		uid += 1
		return uid
	}
	
	var hashValue: Int {
		return uid
	}
	
	public static func ==(lhs: Node, rhs: Node) -> Bool {
		return lhs.hashValue == rhs.hashValue
	}
}

extension Node {
	
	// TODO: cache global/world positions, update if self or a parent changes
	// MARK: Global calculation
	var globalPosition: CGPoint {
		var position = CGPoint.zero
		enumerateUp { node in
			var localPosition = node.position
			if let parent = node.parent {
				localPosition.x *= parent.scale.width
				localPosition.y *= parent.scale.height
			}
			position += localPosition
		}
		return position
	}
	
	var globalZPosition: CGFloat {
		var position: CGFloat = 0
		enumerateUp { node in
			position += node.zPosition
		}
		return position
	}
	
	var globalScale: CGSize {
		var scale = CGSize(width:1,height:1)
		enumerateUp { node in
			scale = CGSize(width:scale.width * node.scale.width, height: scale.height * node.scale.height)
		}
		return scale
	}
	
	var globalFrame: CGRect {
		let bounds = self.bounds
		var rect = CGRect()
		rect.origin = globalPosition
		let scale = globalScale
		let scaledSize = CGSize(width: bounds.width * scale.width, height: -bounds.height * scale.height)
		rect.origin.x -= scaledSize.width * anchorPoint.x
		rect.size = scaledSize
		rect.origin.y -= scaledSize.height * anchorPoint.y
		return rect
	}
	
	var globalRotation: CGFloat {
		var rotation: CGFloat = 0
		enumerateUp { node in
			rotation += node.rotation
		}
		return rotation
	}
	
	var globalTransform: CGAffineTransform {
		var transform = CGAffineTransform.identity
		enumerateUp { node in
			transform = transform.concatenating(node.transform)
		}
		return transform
	}
	
	func enumerateUp(using block: @escaping(_ parent:Node)->()) {
		var node:Node? = self
		while let currentNode = node {
			block(currentNode)
			node = currentNode.parent
		}
	}
	
	func convert(worldPosition position:CGPoint) -> CGPoint {
		var localPosition = position - globalPosition
		let scale = self.globalScale
		localPosition.x /= scale.width
		localPosition.y /= scale.height
		return localPosition.applying(globalTransform.inverted())
	}
	
	func convert(position:CGPoint, toNode:Node) -> CGPoint {
		return .zero
	}
	
	func convert(position:CGPoint, fromNode:Node) -> CGPoint {
		return .zero
	}
}

extension Node {
	// MARK: Node finding
	
	var boundingFrameOfChildren: CGRect {
		var boundingFrame = self.frame
		for node in children {
			guard !node.hidden else { continue }
			var nodeFrame = node.boundingFrameOfChildren.applying(node.transform.inverted())
			
			guard !nodeFrame.isNull && !nodeFrame.isInfinite else { continue }
			
			var topLeft = CGPoint(x: nodeFrame.minX, y: nodeFrame.maxY) * scale.width
			var bottomRight = CGPoint(x: nodeFrame.maxX, y: nodeFrame.minY) * scale.height
			
			topLeft += position
			bottomRight += position
			
			nodeFrame = CGRect(x: topLeft.x, y: topLeft.y, width: bottomRight.x - topLeft.x, height: bottomRight.y - topLeft.y)
			
			boundingFrame = boundingFrame.union(nodeFrame)
		}
		return boundingFrame.applying(transform)
	}
	
	/// Searches the reciever for nodes in it's local coordinate space
	///
	/// - Parameter position: position in world space
	/// - Parameter predicate: Closure to which the node needs to comply
	/// - Returns: lowest childNote at given point
	
	func node(atPosition position: CGPoint, where predicate: ((Node) -> Bool)? = nil) -> Node? {
		
		func applyPredicate(withNode node: Node, predicate: ((Node) -> Bool)?) -> Node? {
			if let predicate = predicate {
				var parent: Node? = node
				while parent != nil {
					if let parent = parent {
						if predicate(parent) {
							return parent
						}
					}
					parent = parent?.parent
				}
				return nil
			} else {
				return self
			}
		}
		
		if children.count == 0 {
			return applyPredicate(withNode: self, predicate: predicate)
		}
		
		for node in children {
			let localPosition = self.convert(worldPosition: position)
			let nodePosition = node.convert(worldPosition: position)
			if node.boundingFrameOfChildren.contains(localPosition) && node.canHandleTouch(atPosition: nodePosition) {
				if let foundNode = node.node(atPosition: position, where: predicate) {
					return foundNode
				} else if let foundNode = applyPredicate(withNode: node, predicate: predicate) {
					return foundNode
				}
			}
		}
		return nil
	}
	
	func interactableNode(atPosition position: CGPoint) -> Node? {
		return node(atPosition: position, where: { $0.enabled && $0.handlesInput })
	}
}
