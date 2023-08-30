import CoreGraphics
/// Source: https://gist.github.com/adamgraham/b2868c72e1d83d432e937bb02b6e27c8
/// An extension to provide conversion to and from CIELAB colors.
extension Color {

    /// The CIELAB components of a color - lightness (L) and chromaticity (a,b).
    struct CIELAB: Hashable {

        /// The lightness component of the color, in the range [0, 100] (darkest to brightest).
        var L: CGFloat
        /// The green-red chromaticity component of the color, typically in the range [-128, 128].
        var a: CGFloat
        /// The blue-yellow chromaticity component of the color, typically in the range [-128, 128].
        var b: CGFloat

    }

    /// A set of constant values used to convert to and from CIELAB colors.
    private struct Constant {

        static let d65: (X: CGFloat, Y: CGFloat, Z: CGFloat) = (95.047, 100.000, 108.883)
        static let ⅓: CGFloat = 1.0 / 3.0
        static let ⁴୵₂₉: CGFloat = 4.0 / 29.0
        static let δ: CGFloat = 6.0 / 29.0
        static let δ³ = δ * δ * δ
        static let δ²3 = δ * δ * 3.0

    }

    /// The CIELAB components of the color using a d65 illuminant and 2° standard observer.
    var Lab: CIELAB {
        func fn(_ t: CGFloat) -> CGFloat {
            if t > Constant.δ³ { return pow(t, Constant.⅓) }
            return (t / Constant.δ²3) + Constant.⁴୵₂₉
        }

        let XYZ = self.XYZ
        let ref = Constant.d65

        let X = fn(XYZ.X / ref.X)
        let Y = fn(XYZ.Y / ref.Y)
        let Z = fn(XYZ.Z / ref.Z)

        let L = (116.0 * Y) - 16.0
        let a = 500.0 * (X - Y)
        let b = 200.0 * (Y - Z)

        return CIELAB(L: L, a: a, b: b)
    }

    /// Initializes a color from CIELAB components.
    /// - parameter Lab: The components used to initialize the color.
    /// - parameter alpha: The alpha value of the color.
    init(_ Lab: CIELAB, alpha: CGFloat = 1.0) {
        func fn(_ t: CGFloat) -> CGFloat {
            if t > Constant.δ { return pow(t, 3.0) }
            return Constant.δ²3 * (t - Constant.⁴୵₂₉)
        }

        let ref = Constant.d65

        let L = (Lab.L + 16.0) / 116.0
        let a = L + (Lab.a / 500.0)
        let b = L - (Lab.b / 200.0)

        let X = fn(a) * ref.X
        let Y = fn(L) * ref.Y
        let Z = fn(b) * ref.Z

        self.init(CIEXYZ(X: X, Y: Y, Z: Z), alpha: alpha)
    }

}
