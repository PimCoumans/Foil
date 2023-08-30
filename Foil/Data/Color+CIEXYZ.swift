import CoreGraphics
/// Source: https://gist.github.com/adamgraham/677c0c41901f3eafb441951de9bc914c
/// An extension to provide conversion to and from CIE 1931 XYZ colors.
extension Color {

    /// The CIE 1931 XYZ components of a color - luminance (Y) and chromaticity (X,Z).
    struct CIEXYZ: Hashable {

        /// A mix of cone response curves chosen to be orthogonal to luminance and
        /// non-negative, in the range [0, 95.047].
        var X: CGFloat
        /// The luminance component of the color, in the range [0, 100].
        var Y: CGFloat
        /// Somewhat equal to blue, or the "S" cone response, in the range [0, 108.883].
        var Z: CGFloat

    }

    /// The CIE 1931 XYZ components of the color.
    var XYZ: CIEXYZ {
        var (r, g, b) = (red, green, blue)
        
        // sRGB (D65) gamma correction - inverse companding to get linear values
        r = (r > 0.03928) ? pow((r + 0.055) / 1.055, 2.4) : (r / 12.92)
        g = (g > 0.03928) ? pow((g + 0.055) / 1.055, 2.4) : (g / 12.92)
        b = (b > 0.03928) ? pow((b + 0.055) / 1.055, 2.4) : (b / 12.92)

        // sRGB (D65) matrix transformation
        // http://www.brucelindbloom.com/index.html?Eqn_RGB_XYZ_Matrix.html
        let X = (0.4124564 * r) + (0.3575761 * g) + (0.1804375 * b)
        let Y = (0.2126729 * r) + (0.7151522 * g) + (0.0721750 * b)
        let Z = (0.0193339 * r) + (0.1191920 * g) + (0.9503041 * b)

        return CIEXYZ(X: X * 100.0,
                      Y: Y * 100.0,
                      Z: Z * 100.0)
    }

    /// Initializes a color from CIE 1931 XYZ components.
    /// - parameter XYZ: The components used to initialize the color.
    /// - parameter alpha: The alpha value of the color.
    init(_ XYZ: CIEXYZ, alpha: CGFloat = 1.0) {
        let X = XYZ.X / 100.0
        let Y = XYZ.Y / 100.0
        let Z = XYZ.Z / 100.0

        // sRGB (D65) matrix transformation
        // http://www.brucelindbloom.com/index.html?Eqn_RGB_XYZ_Matrix.html
        var r =  (3.2404542 * X) - (1.5371385 * Y) - (0.4985314 * Z)
        var g = (-0.9692660 * X) + (1.8760108 * Y) + (0.0415560 * Z)
        var b =  (0.0556434 * X) - (0.2040259 * Y) + (1.0572252 * Z)
        
        // sRGB (D65) gamma correction - companding to get non-linear values
        let k: CGFloat = 1.0 / 2.4
        r = (r <= 0.00304) ? (12.92 * r) : (1.055 * pow(r, k) - 0.055)
        g = (g <= 0.00304) ? (12.92 * g) : (1.055 * pow(g, k) - 0.055)
        b = (b <= 0.00304) ? (12.92 * b) : (1.055 * pow(b, k) - 0.055)
        
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }

}
