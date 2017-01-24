//
//  Color.swift
//  Metal2D
//
//  Created by Pim Coumans on 23/01/17.
//  Copyright © 2017 pixelrock. All rights reserved.
//

import Foundation
#if os(iOS)
	import UIKit
	typealias NativeColor = UIColor
#elseif os(OSX)
	import Cocoa
	typealias NativeColor = NSColor
#endif

struct Color {
	var red: Float
	var green: Float
	var blue: Float
	var alpha: Float = 1
	
	init(red: Float, green: Float, blue: Float) {
		self.red = red
		self.green = green
		self.blue = blue
	}
}

// Equatable
extension Color: Equatable {
	static func ==(_ lhs: Color, _ rhs: Color) -> Bool {
		return lhs.red == rhs.red &&
			lhs.green == rhs.green &&
			lhs.blue == rhs.blue &&
			lhs.alpha == rhs.alpha
	}
}

// Native color support
extension Color {
	init(_ color: NativeColor) {
		var r, g, b, a: Float
		#if os(OSX)
			if color.numberOfComponents < 4 {
				let white = Float(color.whiteComponent)
				r = white
				g = white
				b = white
				a = Float(color.alphaComponent)
			}
			else {
				r = Float(color.redComponent)
				g = Float(color.greenComponent)
				b = Float(color.blueComponent)
				a = Float(color.alphaComponent)
			}
		#elseif os(iOS)
			var red: CGFloat = 0
			var green: CGFloat = 0
			var blue: CGFloat = 0
			var alpha: CGFloat = 0
			if !color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
				color.getWhite(&red, alpha: &alpha)
				green = red
				blue = red
			}
			r = Float(red)
			g = Float(green)
			b = Float(blue)
			a = Float(alpha)
		#endif
		
		self.red = r
		self.green = g
		self.blue = b
		self.alpha = a
	}
}

// Convenience
extension Color {
	
	func with(alpha: Float) -> Color {
		var color = self
		color.alpha = alpha
		return color
	}
	
	static var black: Color {
		return Color(red: 1, green: 1, blue: 1)
	}
	
	static var white: Color {
		return Color(red: 1, green: 1, blue: 1)
	}
	
	static var red: Color {
		return Color(red: 1, green: 1, blue: 1)
	}
	
	static var green: Color {
		return Color(red: 1, green: 1, blue: 1)
	}
	
	static var blue: Color {
		return Color(red: 1, green: 1, blue: 1)
	}
	
	static var purple: Color {
		return Color(red: 1, green: 0, blue: 1)
	}
	
	static var yellow: Color {
		return Color(red: 1, green: 1, blue: 0)
	}
}

// Animation
extension Color: Lerpable {
	mutating func lerp(to color: Color, t: Double) {
		if self == color {
			return
		}
		red.lerp(to: color.red, t: t)
		green.lerp(to: color.green, t: t)
		blue.lerp(to: color.blue, t: t)
		alpha.lerp(to: color.alpha, t: t)
	}
}
fileprivate extension Float {
	mutating func lerp(to float: Float, t: Double) {
		if self == float {
			return
		}
		let difference = float - self
		if abs(difference) < 0.001 {
			self = float
			return
		}
		self += difference * Float(t)
	}
}
