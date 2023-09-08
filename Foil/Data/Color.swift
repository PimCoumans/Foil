//
//  Color.swift
//  Foil
//
//  Created by Pim Coumans on 23/01/17.
//  Copyright © 2017 pixelrock. All rights reserved.
//

import Foundation
import simd
#if os(iOS)
import UIKit
typealias NativeColor = UIColor
#elseif os(OSX)
import Cocoa
typealias NativeColor = NSColor
#endif

struct Color {
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
    var alpha: CGFloat = 1
    
    init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
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
        var r, g, b, a: CGFloat
        #if os(OSX)
        if color.numberOfComponents < 4 {
            let white = color.whiteComponent
            r = white
            g = white
            b = white
            a = color.alphaComponent
        }
        else {
            r = color.redComponent
            g = color.greenComponent
            b = color.blueComponent
            a = color.alphaComponent
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
        r = red
        g = green
        b = blue
        a = alpha
        #endif
        
        self.red = r
        self.green = g
        self.blue = b
        self.alpha = a
    }
}

// Convenience
extension Color {
    
    func with(alpha: CGFloat) -> Color {
        var color = self
        color.alpha = alpha
        return color
    }
    
    static var black: Color {
        return Color(red: 0, green: 0, blue: 0)
    }
    
    static var white: Color {
        return Color(red: 1, green: 1, blue: 1)
    }
    
    static var red: Color {
        return Color(red: 1, green: 0, blue: 0)
    }
    
    static var green: Color {
        return Color(red: 0, green: 1, blue: 0)
    }
    
    static var blue: Color {
        return Color(red: 0, green: 0, blue: 1)
    }
    
    static var purple: Color {
        return Color(red: 1, green: 0, blue: 1)
    }
    
    static var yellow: Color {
        return Color(red: 1, green: 1, blue: 0)
    }
}

extension Color {
	var float4: packed_float4 {
		return packed_float4(
			x: simd_float1(red),
			y: simd_float1(green),
			z: simd_float1(blue),
			w: simd_float1(alpha)
		)
	}
}
