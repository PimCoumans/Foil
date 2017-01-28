//
//  Animator.swift
//  Metal2D
//
//  Created by Pim Coumans on 23/01/17.
//  Copyright © 2017 pixelrock. All rights reserved.
//

import Foundation
import CoreGraphics

class Animation {
	
	let curve: AnimationCurve
	let duration: TimeInterval
	
	var repeats: Bool = false
	
	fileprivate(set)
	var isRunning: Bool = false
	private(set)
	var hasCompleted: Bool = false
	private(set)
	var progressedTime: TimeInterval = 0
	
	var progress: Double {
		return curve.value(for: progressedTime / duration)
	}
	
	init(curve: AnimationCurve, duration: TimeInterval, repeats: Bool = false) {
		self.curve = curve
		self.duration = duration
		self.repeats = repeats
	}
	
	@discardableResult func start() -> Self {
		if !Animator.shared.animations.contains(self) {
			Animator.start(self)
		}
		return self
	}
	
	func stop() {
		isRunning = false
		hasCompleted = true
	}
	
	@discardableResult func loop() -> Self {
		repeats = true
		return self
	}
	
	@discardableResult func reset() -> Self {
		hasCompleted = false
		progressedTime = 0
		return self
	}
	
	func update(delta: TimeInterval) {
		let totalTime = progressedTime + delta
		if repeats {
			progressedTime = totalTime.truncatingRemainder(dividingBy: duration)
		} else {
			progressedTime = min(totalTime, duration)
		}
		didUpdate(delta: delta)
		if progressedTime >= duration {
			isRunning = false
			hasCompleted = true
		}
	}
	
	func didUpdate(delta: TimeInterval) {}
}

extension Animation: Equatable {
	static func ==(lhs: Animation, rhs: Animation) -> Bool {
		return lhs === rhs
	}
}

struct Property: RawRepresentable, Equatable, Hashable {
    
    var rawValue: String
    var index: Int
    
    init(rawValue: Property.RawValue) {
        self.rawValue = rawValue
        self.index = 0
    }
    
    init(_ rawValue: Property.RawValue, at index: Int) {
        self.rawValue = rawValue
        self.index = index
    }
    
    static var position: Property = Property(rawValue:"position")
    static let scale: Property = Property(rawValue:"scale")
    static let rotation: Property = Property(rawValue:"rotation")
    
    var hashValue: Int {
        return rawValue.hash
    }
    
    static func ==(lhs: Property, rhs: Property) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

class PropertyAnimation<T:Lerpable>: Animation {
	
	private(set)
	weak var target: Node?
	
	let property: Property
	var startValue: T?
	let endValue: T
	
	init(on target: Node, property: Property, startValue: T? = nil, endValue: T, curve: AnimationCurve, duration: TimeInterval, repeats: Bool = false) {
		self.target = target
		self.property = property
		self.startValue = startValue
		self.endValue = endValue
		super.init(curve: curve, duration: duration, repeats: repeats)
	}
	
	override func update(delta: TimeInterval) {
		if startValue == nil && (!isRunning || progressedTime == 0) {
			startValue = target?.get(property)
		}
		super.update(delta: delta)
	}
	
	override func didUpdate(delta: Double) {
		if let value = startValue {
			let currentValue = value.lerped(to: endValue, t: progress)
			target?.set(property, value: currentValue)
		}
	}
}

class SequenceAnimation: Animation {
	
	var sequence = [[Animation]]()
	var finishedSequence = [[Animation]]()
	
	func add(_ animation: Animation) {
		sequence.append([animation])
	}
	
	@discardableResult func animate(using block:() -> Void) -> Self {
		let animator = Animator.shared
		let previousContext = animator.animationContext
		animator.animationContext = AnimationContext(duration: duration, curve: curve)
		block()
		animator.animationContext = previousContext
		sequence.append(animator.queuedAnimations)
		animator.queuedAnimations.removeAll()
		return self.start()
	}
	
	override func update(delta: TimeInterval) {
		var remainingTime: Double = 0
		repeat {
			if let animations = sequence.first {
				var animationsFinished = true
				for animation in animations {
					animation.isRunning = true
					remainingTime = max(remainingTime, animation.progressedTime - animation.duration)
					animation.update(delta: delta)
					if animation.isRunning {
						animationsFinished = false
					}
				}
				if !animationsFinished {
					break
				} else {
					finishedSequence.append(sequence.removeFirst())
				}
			} else {
				if repeats {
					sequence = finishedSequence.map { animations -> [Animation] in
						return animations.map { $0.reset() }
					}
					finishedSequence.removeAll()
				} else {
					isRunning = false
					return
				}
			}
		} while remainingTime < delta
		didUpdate(delta: delta)
	}
}

fileprivate struct AnimationContext {
	let duration: TimeInterval
	let curve: AnimationCurve
}

class Animator {
	
	var animations = [Animation]()
	var runningAnimations: [Animation] {
		return animations.filter({$0.isRunning})
	}
	
	static let shared = {
		return Animator()
	}()
	
	fileprivate var animationContext: AnimationContext?
	var queuedAnimations = [Animation]()
	
	class func animate(duration: TimeInterval, curve: AnimationCurve, using block:() -> Void) {
		shared.animationContext = AnimationContext(duration: duration, curve: curve)
		block()
		shared.animationContext = nil
		shared.dequeueAnimations()
	}
	
	class func start(_ animation: Animation) {
		shared.queuedAnimations.append(animation)
		if shared.animationContext == nil {
			shared.dequeueAnimations()
		}
	}
	
	func dequeueAnimations() {
		for animation in queuedAnimations {
			animation.isRunning = true
			animations.append(animation)
		}
		queuedAnimations.removeAll()
	}
	
	func update(with context: RenderContext) {
		for animation in runningAnimations {
			animation.update(delta: context.delta)
			if !animation.isRunning && animation.hasCompleted {
				if let index = animations.index(of: animation) {
					animations.remove(at: index)
				}
			}
		}
	}
}

extension Node {
    
	@discardableResult func animate<T:Lerpable>(_ property: Property, from startValue: T? = nil, to endValue: T, duration: TimeInterval? = nil, curve: AnimationCurve? = nil) -> Animation {
		let context = Animator.shared.animationContext
		guard let animationDuration = duration ?? context?.duration,
			let animationCurve = curve ?? context?.curve else {
				preconditionFailure("no duration or curve set or available")
		}
		
		let animation = PropertyAnimation(on: self, property: property, startValue:startValue, endValue:endValue, curve: animationCurve, duration: animationDuration)
		Animator.start(animation)
		return animation
	}
}
