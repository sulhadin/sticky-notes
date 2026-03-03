import SwiftUI

enum NoteColor: String, Codable, CaseIterable, Identifiable {
    case silver
    case spaceGray
    case gold
    case roseGold
    case blue
    case purple

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .silver: return "Silver"
        case .spaceGray: return "Space Gray"
        case .gold: return "Gold"
        case .roseGold: return "Rose Gold"
        case .blue: return "Blue"
        case .purple: return "Purple"
        }
    }

    // Premium colors from app icon (light mode)
    var backgroundColor: Color {
        switch self {
        case .silver: return Color(hex: "D8D9DC")
        case .spaceGray: return Color(hex: "9A9BA0")
        case .gold: return Color(hex: "E8D4B8")
        case .roseGold: return Color(hex: "E8BCB6")
        case .blue: return Color(hex: "B8CCF0")
        case .purple: return Color(hex: "D5C0EC")
        }
    }

    // Dark mode variants
    var darkBackgroundColor: Color {
        switch self {
        case .silver: return Color(hex: "3A3A3C")
        case .spaceGray: return Color(hex: "2C2C2E")
        case .gold: return Color(hex: "4A4035")
        case .roseGold: return Color(hex: "4A3535")
        case .blue: return Color(hex: "2C3A4A")
        case .purple: return Color(hex: "3A2C4A")
        }
    }

    var textColor: Color {
        switch self {
        case .spaceGray: return Color(hex: "1D1D1F")
        default: return Color(hex: "1D1D1F")
        }
    }

    var darkTextColor: Color {
        Color(hex: "F5F5F7")
    }

    // Slightly darker border colors (light mode)
    var borderColor: Color {
        switch self {
        case .silver: return Color(hex: "C0C1C5")
        case .spaceGray: return Color(hex: "828288")
        case .gold: return Color(hex: "D0BCA0")
        case .roseGold: return Color(hex: "D0A4A0")
        case .blue: return Color(hex: "A0B4D8")
        case .purple: return Color(hex: "BDA8D4")
        }
    }

    // Slightly lighter border colors (dark mode)
    var darkBorderColor: Color {
        switch self {
        case .silver: return Color(hex: "505052")
        case .spaceGray: return Color(hex: "424244")
        case .gold: return Color(hex: "5A5045")
        case .roseGold: return Color(hex: "5A4545")
        case .blue: return Color(hex: "3C4A5A")
        case .purple: return Color(hex: "4A3C5A")
        }
    }

    func background(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkBackgroundColor : backgroundColor
    }

    func text(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkTextColor : textColor
    }

    func border(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkBorderColor : borderColor
    }
}
