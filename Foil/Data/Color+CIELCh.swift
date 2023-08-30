import CoreGraphics
/// Source:  https://gist.github.com/adamgraham/3aef9b8a26f1fef32d1ab30340b0a685
/// An extension to provide conversion to and from CIELCh° colors.
extension Color {

    /// The CIELCh° components of a color - lightness (L), chroma (C), and hue (h).
    struct CIELCh: Hashable {

        /// The lightness component of the color, in the range [0, 100] (darkest to brightest).
        var L: CGFloat
        /// The chroma component of the color.
        var C: CGFloat
        /// The hue component of the color, in the range [0, 360°].
        var h: CGFloat

    }

    /**
     Calculates the CIELCh° components from a lightness value and a pair of chromaticity
     coordinates.

     - parameter L: The lightness value of the color.
     - parameter x: The x-axis chromaticity coordinate of the color.
     - parameter y: The y-axis chromaticity coordinate of the color.

     - returns: The CIELCh° components of the color.
     */
    private func LCh(L: CGFloat, x: CGFloat, y: CGFloat) -> CIELCh {
        let C = sqrt((x * x) + (y * y))
        var h = atan2(y, x)

        if h.isNaN || C.isZero {
            h = 0.0
        } else if h >= 0.0 {
            h = rad2deg(h)
        } else {
            h = 360.0 - rad2deg(abs(h))
        }

        return CIELCh(L: L, C: C, h: h)
    }

    // MARK: CIELCh°(ab)

    /// The CIELCh°(ab) components of the color using a d65 illuminant and 2° standard observer.
    var LCh_ab: CIELCh {
        let Lab = self.Lab
        return LCh(L: Lab.L, x: Lab.a, y: Lab.b)
    }

    /// Initializes a color from CIELCh°(ab) components.
    /// - parameter LCh: The components used to initialize the color.
    /// - parameter alpha: The alpha value of the color.
    init(ab LCh: CIELCh, alpha: CGFloat = 1.0) {
        let a = LCh.C * cos(deg2rad(LCh.h))
        let b = LCh.C * sin(deg2rad(LCh.h))

        self.init(CIELAB(L: LCh.L, a: a, b: b), alpha: alpha)
    }

    // MARK: CIELCh°(uv)

    /// The CIELCh°(uv) components of the color using a d65 illuminant and 2° standard observer.
    var LCh_uv: CIELCh {
        let Luv = self.Luv
        return LCh(L: Luv.L, x: Luv.u, y: Luv.v)
    }

    /// Initializes a color from CIELCh°(uv) components.
    /// - parameter LCh: The components used to initialize the color.
    /// - parameter alpha: The alpha value of the color.
    init(uv LCh: CIELCh, alpha: CGFloat = 1.0) {
        let u = LCh.C * cos(deg2rad(LCh.h))
        let v = LCh.C * sin(deg2rad(LCh.h))

        self.init(CIELUV(L: LCh.L, u: u, v: v), alpha: alpha)
    }

}

// MARK: Helpers
    
/// Converts degrees to radians. 1° × π/180 = 0.01745rad
/// - parameter degrees: The amount of degrees to convert to radians.
/// - returns: The amount of radians equal to the amount of degrees.
private func deg2rad(_ degrees: CGFloat) -> CGFloat {
    return degrees * .pi / 180.0
}

/// Converts radians to degrees. 1rad × 180/π = 57.296°
/// - parameter radians: The amount of radians to convert to degrees.
/// - returns: The amount of degrees equal to the amount of radians.
private func rad2deg(_ radians: CGFloat) -> CGFloat {
    return radians * 180.0 / .pi
}
