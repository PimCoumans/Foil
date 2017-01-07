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

class Node: Interactable {
    
    // MARK: Geometry
	// Position and scale are based on the parents local coordinate system
	// If the parent has a scale of 2, this node has a scale of 1
	// it will be rendered twice as big
    var position = CGPoint.zero
    var anchorPoint = CGPoint(x: 0.5, y: 0.5)
    var scale = CGSize(width: 1, height: 1)
	var frame: CGRect {
		return CGRect(origin: position, size: .zero)
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
        render(with: context)
        for node in children {
			node.renderRecursively(with:context)
        }
    }
	
	// MARK: Interactable
	var handlesInput: Bool { return false }
	
	var enabled: Bool = true
	var highlighted: Bool = false
	var selected: Bool = false
	
	var highlightedChildNode: Node? = nil
	var selectedChildNode: Node? = nil
	
	func touchBegan(atPosition point: CGPoint) {}
	func touchMoved(toPosition point: CGPoint, delta: CGPoint) {}
	func touchEnded(atPosition point: CGPoint, delta: CGPoint) {}
	func touchCancelled() {}
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
	
	var globalScale: CGSize {
		var scale = CGSize(width:1,height:1)
		enumerateUp { node in
			scale = CGSize(width:scale.width * node.scale.width, height: scale.height * node.scale.height)
		}
		return scale
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
		return localPosition
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
			var nodeFrame = node.boundingFrameOfChildren
			
			var topLeft = CGPoint(x: nodeFrame.minX, y: nodeFrame.minY) * scale.width
			var bottomRight = CGPoint(x: nodeFrame.maxX, y: nodeFrame.maxY) * scale.height
			
			topLeft += position
			bottomRight += position
			
			nodeFrame = CGRect(x: topLeft.x, y: topLeft.y, width: bottomRight.x - topLeft.x, height: bottomRight.y - topLeft.y)			
			
			boundingFrame = boundingFrame.union(nodeFrame)
		}
		return boundingFrame
	}
	
	/// Searches the reciever for nodes in it's local coordinate space
	///
	/// - Parameter position: position in world space
	/// - Parameter predicate: Closure to which the node needs to comply
	/// - Returns: lowest childNote at given point
	
	func node(atPosition position: CGPoint, where predicate: ((Node) -> Bool)? = nil) -> Node? {
		if children.count == 0 {
			if let predicate = predicate {
				var parent: Node? = self
				while parent != nil {
					if let parent = parent {
//						let localPosition = parent.convert(worldPosition: position)
						if predicate(parent) {
							return parent
						}
						else {
//							print("No likey predicate: \(parent)")
						}
					}
					parent = parent?.parent
				}
			} else {
				return self
			}
			return nil
		}
		
		for node in children {
			let localPosition = self.convert(worldPosition: position)
			if node.boundingFrameOfChildren.contains(localPosition) {
				if let foundNode = node.node(atPosition: position, where: predicate) {
					return foundNode
				}
			}
			else {
//				print("No in bounds '\(node)': \(localPosition)")
			}
		}
		return nil
	}
	
	func interactableNode(atPosition position: CGPoint) -> Node? {
		return node(atPosition: position, where: { $0.enabled && $0.handlesInput })
	}
}
