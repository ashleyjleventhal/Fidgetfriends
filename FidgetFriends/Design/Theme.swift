import SwiftUI

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

enum Palette {
    static let grape = Color(hex: 0x6938C5)
    static let grapeDeep = Color(hex: 0x4E2499)
    static let tangerine = Color(hex: 0xFF8A3D)
    static let tangerineDeep = Color(hex: 0xE0651A)
    static let coral = Color(hex: 0xFF936F)
    static let coralDeep = Color(hex: 0xD9603A)
    static let mint = Color(hex: 0x2FC99E)
    static let mintDeep = Color(hex: 0x15997A)
    static let mintPastel = Color(hex: 0xC5EBD7)
    static let sunshine = Color(hex: 0xFFE181)
    static let sunshineDeep = Color(hex: 0xE0B43A)
    static let sunshinePastel = Color(hex: 0xFFF2B8)
    static let bubblegum = Color(hex: 0xFFB3D4)
    static let peachPastel = Color(hex: 0xFFE1CC)
    static let sky = Color(hex: 0x5DB8FF)
    static let skyDeep = Color(hex: 0x2B86D6)
    static let skyPastel = Color(hex: 0xD5E8FF)
    static let lilac = Color(hex: 0xEEE2FF)
    static let cream = Color(hex: 0xFFFCF6)
    static let ink = Color(hex: 0x35254F)
    static let inkSoft = Color(hex: 0x65558A)
    static let blush = Color(hex: 0xFF8FB1)
}

extension Font {
    static func fun(_ style: Font.TextStyle, weight: Font.Weight = .bold) -> Font {
        .system(style, design: .rounded).weight(weight)
    }
}
