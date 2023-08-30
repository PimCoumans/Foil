//
//  RenderView+Interaction.swift
//  Foil
//
//  Created by Pim Coumans on 01/01/17.
//  Copyright © 2017 pixelrock. All rights reserved.
//

#if os(iOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

extension RenderView {
    
    var pixelScale: CGFloat {
        let screenSize = screen.bounds.size
        let minScreenBounds = min(screenSize.width, screenSize.height)
        let minViewSize = min(bounds.width, bounds.height)
        return minScreenBounds / minViewSize
    }
    
    var isInteracting: Bool {
        return scene?.inputReceivingNode != nil
    }
    
    func touchBegan(atPoint point: CGPoint) {
        let worldPosition = self.worldPosition(forScreenPosition: point)
        if let node = scene?.inputReceivingNode ?? scene?.interactableNode(atPosition: worldPosition) {
            scene?.inputReceivingNode = node
            let localPosition = node.convert(worldPosition: worldPosition)
            node.touchBegan(atPosition: localPosition)
        }
        else {
            scene?.inputReceivingNode = scene
            scene?.touchBegan(atPosition: worldPosition)
        }
    }
    
    func touchMoved(toPoint point: CGPoint, delta:CGPoint) {
        if let node = scene?.inputReceivingNode {
            let worldPosition = self.worldPosition(forScreenPosition: point)
            var worldDelta = delta * pixelScale
            worldDelta.y = -worldDelta.y
            let localPosition = node.convert(worldPosition: worldPosition)
            let localDelta = localPosition - node.convert(worldPosition: worldPosition + worldDelta)
            node.touchMoved(toPosition: localPosition, delta: localDelta)
        }
    }
    
    func touchEnded(atPoint point:CGPoint, delta:CGPoint) {
        if let node = scene?.inputReceivingNode {
            scene?.inputReceivingNode = nil
            let worldPosition = self.worldPosition(forScreenPosition: point)
            var worldDelta = delta * pixelScale
            worldDelta.y = -worldDelta.y
            let localPosition = node.convert(worldPosition: worldPosition)
            let localDelta = localPosition - node.convert(worldPosition: worldPosition + worldDelta)
            node.touchEnded(atPosition: localPosition, delta: localDelta)
        }
    }
    
    func touchCancelled() {
        if let node = scene?.inputReceivingNode {
            node.touchCancelled()
        }
        scene?.inputReceivingNode = nil
    }
    
    func worldPosition(forScreenPosition screenPosition:CGPoint) -> CGPoint {
        var point = CGPoint(x: screenPosition.x / bounds.width, y: screenPosition.y / bounds.height)
        #if os(iOS)
        point.y = 1 - point.y
        #endif
        let screenBounds = screen.bounds
        point.x *= screenBounds.width
        point.y *= screenBounds.height
        point += screenBounds.origin
        return point
    }
    
    #if os(OSX)
    // FIXME: Use gesture recognizers instead of mouse events
    override func mouseDown(with event: NSEvent) {
        let location = event.locationInWindow
        touchBegan(atPoint: location)
    }
    
    override func mouseDragged(with event: NSEvent) {
        let location = event.locationInWindow
        let delta = CGPoint(x:event.deltaX, y:event.deltaY)
        touchMoved(toPoint: location, delta: delta)
    }
    
    override func mouseUp(with event: NSEvent) {
        let location = event.locationInWindow
        let delta = CGPoint(x:event.deltaX, y:event.deltaY)
        // FIXME: Delta does not work when released
        touchEnded(atPoint: location, delta: delta)
    }
    #elseif os(iOS)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        touchBegan(atPoint: touch.location(in: self))
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let previousLocation = touch.previousLocation(in: self)
        let delta = CGPoint(x: location.x - previousLocation.x, y: location.y - previousLocation.y)
        touchMoved(toPoint: location, delta: delta)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let previousLocation = touch.previousLocation(in: self)
        let delta = CGPoint(x: location.x - previousLocation.x, y: location.y - previousLocation.y)
        touchEnded(atPoint: location, delta: delta)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchCancelled()
    }
    #endif
    
}
