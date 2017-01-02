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
    
    override weak var renderView: RenderView? {
        didSet {
            if let renderView = renderView {
                #if os(iOS)
                    let image = UIImage(named:"pim")
                #elseif os(OSX)
                    let image = NSImage(named:"pim")
                #endif
                renderView.screen.zoomScale = 60
                textureNode = TextureNode(renderView: renderView, image: image, size:CGSize(width:20, height:20))
                addChild(textureNode)
            }
        }
    }
    
    var moveDirection = CGPoint(x: 1, y: 1)
    override func update() {
        guard let renderView = renderView, selectedChildNode == nil else { return }
        
        textureNode.position.x += moveDirection.x
        textureNode.position.y += moveDirection.y
        let boundingRect = textureNode.boundingRect
        let screenbounds = renderView.screen.bounds
        if boundingRect.maxX >= screenbounds.maxX {
            textureNode.position.x = screenbounds.maxX - (textureNode.size.width / 2)
            moveDirection.x = 0 - moveDirection.x
        }
        else if boundingRect.minX <= screenbounds.minX {
            textureNode.position.x = screenbounds.minX + (textureNode.size.width / 2)
            moveDirection.x = 0 - moveDirection.x
        }
        
        if boundingRect.maxY >= screenbounds.maxY {
            textureNode.position.y = screenbounds.maxY - (textureNode.size.height / 2)
            moveDirection.y = 0 - moveDirection.y
        }
        else if boundingRect.minY <= screenbounds.minY {
            textureNode.position.y = screenbounds.minY + (textureNode.size.height / 2)
            moveDirection.y = 0 - moveDirection.y
        }
    }
    
    override func touchBegan(atPosition position: CGPoint) {
        if let node = node(atPosition: position, where: {$0.frame.contains(position) && $0 != self}) {
            selectedChildNode = node
        }
    }
    
    override func touchMoved(toPosition position: CGPoint, delta: CGPoint) {
        if let node = selectedChildNode {
            node.position = position
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
