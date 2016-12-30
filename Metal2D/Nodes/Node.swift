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

class Node {
    
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
    
    // MARK: Hierarchy
    private(set) var scene:Scene? {
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
    private(set) weak var parent:Node? {
        willSet { willMoveToParent(newValue) }
        didSet { didMoveToParent() }
    }
    private(set) var children = [Node]()
    
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
}

extension Node: Hashable {
    
    private static var uid = 1
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
			position = CGPoint(x:position.x + localPosition.x, y:position.y + localPosition.y)
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
}
