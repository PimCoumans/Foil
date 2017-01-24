//
//  Animator.swift
//  Metal2D
//
//  Created by Pim Coumans on 23/01/17.
//  Copyright © 2017 pixelrock. All rights reserved.
//

import Foundation

protocol Lerpable: Equatable {
	mutating func lerp(to: Self, t: Double)
	func lerped(to: Self, t: Double) -> Self
}

extension Lerpable {
	func lerped(to: Self, t: Double) -> Self {
		var value = self
		value.lerp(to: to, t: t)
		return value
	}
}

class Animation {
	
	let target: Node
	let curve: String
	let duration: TimeInterval
	
	var running: Bool = false
	var progress: Double = 0
	var startTime: CFAbsoluteTime = 0
	
	init(on target: Node, curve: String, duration: TimeInterval) {
		self.target = target
		self.curve = curve
		self.duration = duration
	}
	
	fileprivate func update(delta: Double) {
		
	}
}

class PropertyAnimation<T:Lerpable>: Animation {
	let property: String
	let values: [T]
	
	init(on target: Node, property: String, values: [T], curve: String, duration: TimeInterval) {
		self.property = property
		self.values = values
		super.init(on: target, curve: curve, duration: duration)
	}
	
	fileprivate override func update(delta: Double) {
		target.position = values[0].lerped(to: values[1], t: progress) as! CGPoint
	}
	
}

fileprivate struct AnimationContext {
	let duration: TimeInterval
	let curve: String
}

class Animator {
	
	var animations = [Animation]()
	var runningAnimations = [Animation]()
	
	static let shared = {
		return Animator()
	}()
	
	fileprivate var animationContext: AnimationContext?
	
	class func animate(duration: TimeInterval, curve: String, using block:() -> Void) {
		shared.animationContext = AnimationContext(duration: duration, curve: curve)
		block()
		shared.animationContext = nil
	}
	
	func update(with context: RenderContext) {
		for animation in runningAnimations {
			animation.update(delta: context.delta)
		}
	}
}

extension Node {
	
	func animatePosition(from startPosition: CGPoint? = nil, to endPosition: CGPoint, duration: TimeInterval? = nil, curve: String? = nil) {
		let positions = [startPosition ?? position, endPosition]
		if let context = Animator.shared.animationContext {
			let animationDuration = duration ?? context.duration
			let animationCurve = curve ?? context.curve
			let animation = PropertyAnimation(on: self, property: "position", values: positions, curve: animationCurve, duration: animationDuration)
			Animator.shared.animations.append(animation)
		}
	}
}
