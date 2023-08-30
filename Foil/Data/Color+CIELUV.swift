import CoreGraphics
/// Source: https://gist.github.com/adamgraham/95ab30303e4d43056e79245e4eef9b5f
/// An extension to provide conversion to and from CIELUV colors.
extension Color {

    /// The CIELUV components of a color - lightness (L) and chromaticity (u,v).
    struct CIELUV: Hashable {

        /// The lightness component of the color, in the range [0, 100] (darkest to brightest).
        var L: CGFloat
        /// The green-red chromaticity component of the color, typically in the range [-100, 100].
        var u: CGFloat
        /// The blue-yellow chromaticity component of the color, typically in the range [-100, 100].
        var v: CGFloat

    }

    /// A set of constant values used to convert to and from CIELUV colors.
    private struct Constant {

        static let d65 = CIEXYZ(X: 95.047, Y: 100.000, Z: 108.883)
        static let ⅓: CGFloat = 1.0 / 3.0
        static let ϵ: CGFloat = 216.0 / 24389.0
        static let κ: CGFloat = 24389.0 / 27.0

        static func fu(_ XYZ: CIEXYZ) -> CGFloat {
            return (4.0 * XYZ.X) / (XYZ.X + (15.0 * XYZ.Y) + (3.0 * XYZ.Z))
        }

        static func fv(_ XYZ: CIEXYZ) -> CGFloat {
            return (9.0 * XYZ.Y) / (XYZ.X + (15.0 * XYZ.Y) + (3.0 * XYZ.Z))
        }

    }

    /// The CIELUV components of the color using a d65 illuminant and 2° standard observer.
    var Luv: CIELUV {
        func fL(_ t: CGFloat) -> CGFloat {
            if t <= Constant.ϵ { return t * Constant.κ }
            return 116.0 * pow(t, Constant.⅓) - 16.0
        }

        let XYZ = self.XYZ
        let ref = Constant.d65

        var L = fL(XYZ.Y / ref.Y)
        var u = 13.0 * L * (Constant.fu(XYZ) - Constant.fu(ref))
        var v = 13.0 * L * (Constant.fv(XYZ) - Constant.fv(ref))

        if L.isNaN { L = 0.0 }
        if u.isNaN { u = 0.0 }
        if v.isNaN { v = 0.0 }

        return CIELUV(L: L, u: u, v: v)
    }

    /// Initializes a color from CIELUV components.
    /// - parameter Luv: The components used to initialize the color.
    /// - parameter alpha: The alpha value of the color.
    init(_ Luv: CIELUV, alpha: CGFloat = 1.0) {
        func fL(_ t: CGFloat) -> CGFloat {
            if t <= Constant.κ * Constant.ϵ { return t / Constant.κ }
            return pow((t + 16.0) / 116.0, 3.0)
        }

        let ref = Constant.d65

        let u = Luv.u / (13.0 * Luv.L) + Constant.fu(ref)
        let v = Luv.v / (13.0 * Luv.L) + Constant.fv(ref)

        var Y = fL(Luv.L) * 100.0
        var X = (-9.0 * Y * u) / ((u - 4.0) * v - (u * v))
        var Z = (9.0 * Y - (15.0 * v * Y) - (v * X)) / (3.0 * v)

        if X.isNaN { X = 0.0 }
        if Y.isNaN { Y = 0.0 }
        if Z.isNaN { Z = 0.0 }

        self.init(CIEXYZ(X: X, Y: Y, Z: Z), alpha: alpha)
    }

}
