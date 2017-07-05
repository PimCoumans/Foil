//
//  Interpolatable.swift
//  Foil
//
//  Created by Pim Coumans on 25/01/17.
//  Copyright © 2017 pixelrock. All rights reserved.
//

import CoreGraphics

protocol Lerpable: Equatable {
	mutating func lerp(to: Self, t: Double)
	func lerped(to: Self, t: Double) -> Self
	static func + (lhs: Self, rhs: Self) -> Self
}

extension Lerpable {
	func lerped(to: Self, t: Double) -> Self {
		var value = self
		value.lerp(to: to, t: t)
		return value
	}
}

extension CGFloat: Lerpable {
	mutating internal func lerp(to: CGFloat, t: Double) {
		self += (to - self) * CGFloat(t)
	}
}

protocol AnimationCurve {
	func value(for progress: Double) -> Double
}

struct Linear: AnimationCurve {
	func value(for progress: Double) -> Double {
		return progress
	}
}

struct EaseIn: AnimationCurve {
	func value(for progress: Double) -> Double {
		return progress * progress
	}
}

struct EaseOut: AnimationCurve {
	func value(for progress: Double) -> Double {
		return -(progress * (progress - 2));
	}
}

struct ElasticIn: AnimationCurve {
	func value(for p: Double) -> Double {
		return sin(13 * (Double.pi / 2) * p) * pow(2, 10 * (p - 1));
	}
}

struct ElasticOut: AnimationCurve {
	func value(for p: Double) -> Double {
		return sin(-13 * (Double.pi / 2) * (p + 1)) * pow(2, -10 * p) + 1;
	}
}

struct Spring: AnimationCurve {
	
	var damping: Double
	var mass: Double
	var stiffness: Double
	var velocity: Double = 0
	
	func value(for progress: Double) -> Double {
		if damping <= 0.0 || stiffness <= 0.0 || mass <= 0.0 {
			fatalError("Incorrect animation values")
		}
		
		let beta = damping / (2 * mass)
		let omega0 = sqrt(stiffness / mass)
		let omega1 = sqrt((omega0 * omega0) - (beta * beta))
		let omega2 = sqrt((beta * beta) - (omega0 * omega0))
		
		let x0: Double = -1
		
		let oscillation: (Double) -> Double
		
		if beta < omega0 {
			// Underdamped
			oscillation = {t in
				let envelope = exp(-beta * t)
    
				let part2 = x0 * cos(omega1 * t)
				let part3 = ((beta * x0 + self.velocity) / omega1) * sin(omega1 * t)
				return -x0 + envelope * (part2 + part3)
			}
		} else if beta == omega0 {
			// Critically damped
			oscillation = {t in
				let envelope = exp(-beta * t)
				return -x0 + envelope * (x0 + (beta * x0 + self.velocity) * t)
			}
		} else {
			// Overdamped
			oscillation = {t in
				let envelope = exp(-beta * t)
				let part2 = x0 * cosh(omega2 * t)
				let part3 = ((beta * x0 + self.velocity) / omega2) * sinh(omega2 * t)
				return -x0 + envelope * (part2 + part3)
			}
		}
		
		return oscillation(progress)
	}
}
