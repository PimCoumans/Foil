//
//  RenderView+Interaction.swift
//  Metal2D
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
    
    var pixelScale:CGFloat {
        let screenSize = screen.bounds.size
        let minScreenBounds = min(screenSize.width, screenSize.height)
        let minViewSize = min(bounds.width, bounds.height)
        return minScreenBounds / minViewSize
    }
    
    func touchBegan(atPoint point: CGPoint) {
        scene?.touchBegan(atPoint: globalPoint(forScreenPoint: point))
    }
    
    func touchMoved(toPoint point: CGPoint, delta:CGPoint) {
        let convertedDelta = CGPoint(x:delta.x * pixelScale, y:-delta.y * pixelScale)
        scene?.touchMoved(toPoint:globalPoint(forScreenPoint: point), delta: convertedDelta)
    }
    
    func touchEnded(atPoint point:CGPoint, delta:CGPoint) {
        let convertedDelta = CGPoint(x:delta.x * pixelScale, y:-delta.y * pixelScale)
        scene?.touchEnded(atPoint: globalPoint(forScreenPoint: point), delta: convertedDelta)
    }
    
    func touchCancelled() {
        Swift.print("Cancelled!")
    }
    
    func globalPoint(forScreenPoint screenPoint:CGPoint) -> CGPoint {
        var point = CGPoint(x: screenPoint.x / bounds.width, y: screenPoint.y / bounds.height)
        let screenBounds = screen.bounds
        point.x *= screenBounds.width
        point.y *= 1 - screenBounds.height
        point.x += screenBounds.minX
        point.y -= screenBounds.minY
        return point
    }
    
    #if os(OSX)
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
