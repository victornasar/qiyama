import SwiftUI

enum QiyamaTheme {
    static let ink = Color(red: 0x12 / 255, green: 0x15 / 255, blue: 0x1C / 255)
    static let paper = Color(red: 0xE8 / 255, green: 0xEC / 255, blue: 0xF1 / 255)
    static let slate = Color(red: 0x3A / 255, green: 0x44 / 255, blue: 0x54 / 255)
    static let line = Color(red: 0xC5 / 255, green: 0xCD / 255, blue: 0xD8 / 255)
    static let lantern = Color(red: 0xC4 / 255, green: 0xA3 / 255, blue: 0x5A / 255)
    static let wake = Color(red: 0x0B / 255, green: 0x0D / 255, blue: 0x12 / 255)
    static let wakeText = Color(red: 0xF0 / 255, green: 0xED / 255, blue: 0xE6 / 255)
    static let miss = Color(red: 0x8F / 255, green: 0x4E / 255, blue: 0x4E / 255)
    static let ok = Color(red: 0x4F / 255, green: 0x6F / 255, blue: 0x5C / 255)

    static func display(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func body(_ size: CGFloat = 16, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}
