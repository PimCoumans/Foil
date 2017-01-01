//
//  Interactable.swift
//  Metal2D
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
    
    func touchBegan(atPoint point: CGPoint)
    func touchMoved(toPoint point: CGPoint, delta: CGPoint)
    func touchEnded(atPoint point: CGPoint, delta: CGPoint)
    func touchCancelled()
}
