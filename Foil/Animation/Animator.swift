//
//  Animator.swift
//  Foil
//
//  Created by Pim Coumans on 23/01/17.
//  Copyright © 2017 pixelrock. All rights reserved.
//

import CoreGraphics
import Foundation

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

struct Property: Equatable, Hashable {
    
    let rawValue: String
    let index: Int
    let isRelative: Bool
    
    init(rawValue: String) {
        self.rawValue = rawValue
        self.index = -1
        self.isRelative = false
    }
    
    init(_ rawValue: String, at index: Int = -1, relative: Bool = false) {
        self.rawValue = rawValue
        self.index = index
        self.isRelative = relative
    }
    
    static var position: Property = Property(rawValue:"position")
    static var positionX: Property = Property(rawValue: "positionX")
    static var positionY: Property = Property(rawValue: "positionY")
    
    static let scale: Property = Property(rawValue:"scale")
    static var scaleWidth: Property = Property(rawValue: "scaleWidth")
    static var scaleHeight: Property = Property(rawValue: "scaleHeight")
    
    static let rotation: Property = Property(rawValue:"rotation")
    static let relativeRotation: Property = Property("relativeRotation", relative: true)
    
    var hashValue: Int {
        return rawValue.hashValue + (self.index + 1)
    }
    
    static func ==(lhs: Property, rhs: Property) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

protocol TargetPropertyContainer {
    var target: Animatable? { get } // should always be weak
    var property: Property { get }
}

class PropertyAnimation<T:Lerpable>: Animation, TargetPropertyContainer {
    
    private(set)
    weak var target: Animatable?
    
    let property: Property
    var startValue: T?
    let endValue: T
    
    private let usesStartValue: Bool
    
    init(on target: Animatable, property: Property, startValue: T? = nil, endValue: T, curve: AnimationCurve, duration: TimeInterval, repeats: Bool = false) {
        self.target = target
        self.property = property
        self.startValue = startValue
        self.endValue = endValue
        self.usesStartValue = startValue != nil
        super.init(curve: curve, duration: duration, repeats: repeats)
    }
    
    override func update(delta: TimeInterval) {
        if startValue == nil && (!isRunning || abs(progressedTime) <= delta) {
            startValue = target?.get(property)
        }
        let totalTime = progressedTime + delta
        if property.isRelative && repeats && totalTime > duration {
            self.startValue = target?.get(property)
        }
        super.update(delta: delta)
    }
    
    override func reset() -> Self {
        if !usesStartValue {
            startValue = nil
        }
        return super.reset()
    }
    
    override func didUpdate(delta: Double) {
        if let value = startValue {
            let endValue = property.isRelative ? value + self.endValue : self.endValue
            let currentValue = value.lerped(to: endValue, t: progress)
            target?.update(property, with: currentValue)
        }
    }
}

class ClosureAnimation: Animation {
    var closure: () -> Void
    init(_ closure: @escaping () -> Void) {
        self.closure = closure
        super.init(curve: Linear(), duration: 0)
    }
    
    override func didUpdate(delta: TimeInterval) {
        closure()
        isRunning = false
    }
}

class SequenceAnimation: Animation {
    
    var sequenceQueue = [() -> Void]()
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
    
    @discardableResult func closure(_ closure: @escaping () -> Void) -> Self {
        return animate {
            ClosureAnimation(closure).start()
        }
    }
    
    @discardableResult func wait(for duration: TimeInterval) -> Self {
        return animate {
            Animation(curve: Linear(), duration: duration).start()
        }
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
    
    var isRunningAnimations: Bool {
        return runningAnimations.count > 0
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
    
    @discardableResult class func animate<T:Lerpable>(_ target: Animatable, with property: Property, from startValue: T?, to endValue: T, duration: TimeInterval?, curve: AnimationCurve?) -> Animation {
        let context = Animator.shared.animationContext
        guard let animationDuration = duration ?? context?.duration,
            let animationCurve = curve ?? context?.curve else {
                preconditionFailure("no duration or curve set or available")
        }
        
        let animation = PropertyAnimation(on: target, property: property, startValue:startValue, endValue:endValue, curve: animationCurve, duration: animationDuration)
        Animator.start(animation)
        return animation
        
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

protocol Animatable: class {
    
    func update<T:Lerpable>(_ property:Property, with value:T)
    func set<T:Lerpable>(_ property: Property, value: T)
    func get<T:Lerpable>(_ property: Property) -> T?
    
    func animations() -> [Animation]
    func animations(for property:Property?) -> [Animation]
    func cancelAnimations()
    func cancelAnimations(for property:Property?)
    
    @discardableResult func animate<T:Lerpable>(_ property: Property, from startValue: T?, to endValue: T, duration: TimeInterval?, curve: AnimationCurve?) -> Animation
}

extension Animatable {
    
    func update<T:Lerpable>(_ property:Property, with value:T) {
        set(property, value: value)
    }
    
    func animations(for property:Property? = nil) -> [Animation] {
        return Animator.shared.runningAnimations.filter({ animation -> Bool in
            guard let animation = animation as? TargetPropertyContainer, animation.target === self else {
                return false
            }
            guard let property = property else {
                return true
            }
            return animation.property == property
        })
    }
    
    func animations() -> [Animation] {
        return animations(for: nil)
    }
    
    func cancelAnimations(for property:Property? = nil) {
        for animation in animations(for: property) {
            animation.stop()
            if let index = Animator.shared.animations.index(of: animation) {
                Animator.shared.animations.remove(at: index)
            }
        }
    }
    
    func cancelAnimations() {
        return cancelAnimations(for: nil)
    }
    
    @discardableResult func animate<T:Lerpable>(_ property: Property, from startValue: T? = nil, to endValue: T, duration: TimeInterval? = nil, curve: AnimationCurve? = nil) -> Animation {
        cancelAnimations(for: property)
        return Animator.animate(self, with: property, from: startValue, to: endValue, duration: duration, curve: curve)
    }
}
