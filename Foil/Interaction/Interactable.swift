//
//  Interactable.swift
//  Foil
//
//  Created by Pim Coumans on 01/01/17.
//  Copyright © 2017 pixelrock. All rights reserved.
//

import QuartzCore

protocol Interactable {
    
    var handlesInput: Bool { get }
    
    var enabled: Bool { get set }
    var highlighted: Bool { get set }
    var selected: Bool { get set }
    
    var highlightedChildNode: Node? { get set }
    var selectedChildNode: Node? { get set }
    
    func canHandleTouch(atPosition position: CGPoint) -> Bool
    func touchBegan(atPosition position: CGPoint)
    func touchMoved(toPosition position: CGPoint, delta: CGPoint)
    func touchEnded(atPosition position: CGPoint, delta: CGPoint)
    func touchCancelled()
}
