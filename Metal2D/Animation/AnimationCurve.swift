//
//  Interpolatable.swift
//  Metal2D
//
//  Created by Pim Coumans on 25/01/17.
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
		return sin(13 * M_PI_2 * p) * pow(2, 10 * (p - 1));
	}
}

struct ElasticOut: AnimationCurve {
	func value(for p: Double) -> Double {
		return sin(-13 * M_PI_2 * (p + 1)) * pow(2, -10 * p) + 1;
	}
}
