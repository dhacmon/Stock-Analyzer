import Foundation
import SwiftUI

// MARK: - Snow Data Models

struct SnowData: Codable, Equatable {
    var topDepth: Int      // Snow depth at summit in cm
    var bottomDepth: Int   // Snow depth at base in cm
    var newSnow24h: Int    // New snow in last 24h in cm
    var newSnow48h: Int    // New snow in last 48h in cm

    var topDepthInches: Double { Double(topDepth) / 2.54 }
    var bottomDepthInches: Double { Double(bottomDepth) / 2.54 }
    var newSnow24hInches: Double { Double(newSnow24h) / 2.54 }
    var newSnow48hInches: Double { Double(newSnow48h) / 2.54 }
}

struct SnowRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    let topDepth: Int
    let bottomDepth: Int
    let newSnow: Int

    init(id: UUID = UUID(), date: Date, topDepth: Int, bottomDepth: Int, newSnow: Int) {
        self.id = id
        self.date = date
        self.topDepth = topDepth
        self.bottomDepth = bottomDepth
        self.newSnow = newSnow
    }
}

// MARK: - Weather Models

struct DayForecast: Identifiable, Codable {
    let id: UUID
    let date: Date
    let highTemp: Int
    let lowTemp: Int
    let condition: WeatherCondition
    let snowfallChance: Int
    let expectedSnowfall: Int
    let windSpeed: Int

    init(id: UUID = UUID(), date: Date, highTemp: Int, lowTemp: Int, condition: WeatherCondition, snowfallChance: Int, expectedSnowfall: Int, windSpeed: Int) {
        self.id = id
        self.date = date
        self.highTemp = highTemp
        self.lowTemp = lowTemp
        self.condition = condition
        self.snowfallChance = snowfallChance
        self.expectedSnowfall = expectedSnowfall
        self.windSpeed = windSpeed
    }
}

enum WeatherCondition: String, Codable, CaseIterable {
    case sunny = "sunny"
    case partlyCloudy = "partly_cloudy"
    case cloudy = "cloudy"
    case lightSnow = "light_snow"
    case heavySnow = "heavy_snow"
    case blizzard = "blizzard"

    var icon: String {
        switch self {
        case .sunny: return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .cloudy: return "cloud.fill"
        case .lightSnow: return "cloud.snow.fill"
        case .heavySnow: return "snow"
        case .blizzard: return "wind.snow"
        }
    }

    var description: String {
        switch self {
        case .sunny: return "Sunny"
        case .partlyCloudy: return "Partly Cloudy"
        case .cloudy: return "Cloudy"
        case .lightSnow: return "Light Snow"
        case .heavySnow: return "Heavy Snow"
        case .blizzard: return "Blizzard"
        }
    }

    var color: Color {
        switch self {
        case .sunny: return .yellow
        case .partlyCloudy: return .orange
        case .cloudy: return .gray
        case .lightSnow: return .cyan
        case .heavySnow: return .blue
        case .blizzard: return .indigo
        }
    }
}

// MARK: - Resort Models

struct SkiResort: Identifiable, Codable {
    let id: UUID
    let name: String
    let country: String
    let elevation: Int
    let trails: Int

    init(id: UUID = UUID(), name: String, country: String, elevation: Int, trails: Int) {
        self.id = id
        self.name = name
        self.country = country
        self.elevation = elevation
        self.trails = trails
    }

    static let popular: [SkiResort] = [
        SkiResort(name: "Whistler Blackcomb", country: "Canada", elevation: 2284, trails: 200),
        SkiResort(name: "Vail", country: "USA", elevation: 3527, trails: 195),
        SkiResort(name: "Park City", country: "USA", elevation: 3048, trails: 330),
        SkiResort(name: "Aspen Snowmass", country: "USA", elevation: 3813, trails: 336),
        SkiResort(name: "Chamonix", country: "France", elevation: 3842, trails: 182),
        SkiResort(name: "Zermatt", country: "Switzerland", elevation: 3883, trails: 200),
        SkiResort(name: "Niseko", country: "Japan", elevation: 1308, trails: 61),
        SkiResort(name: "St. Anton", country: "Austria", elevation: 2811, trails: 300),
        SkiResort(name: "Mammoth Mountain", country: "USA", elevation: 3369, trails: 150),
        SkiResort(name: "Jackson Hole", country: "USA", elevation: 3185, trails: 133),
    ]
}

// MARK: - Countdown Components

struct CountdownComponents {
    let days: Int
    let hours: Int
    let minutes: Int
    let seconds: Int

    var isInPast: Bool { days < 0 || hours < 0 || minutes < 0 || seconds < 0 }

    static func from(date: Date) -> CountdownComponents {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .hour, .minute, .second], from: now, to: date)

        return CountdownComponents(
            days: max(0, components.day ?? 0),
            hours: max(0, components.hour ?? 0),
            minutes: max(0, components.minute ?? 0),
            seconds: max(0, components.second ?? 0)
        )
    }
}

// MARK: - Theme Colors

struct AppTheme {
    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "1a1a2e"), Color(hex: "16213e"), Color(hex: "0f3460")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentGradient = LinearGradient(
        colors: [Color(hex: "00d4ff"), Color(hex: "7c3aed")],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let snowGradient = LinearGradient(
        colors: [Color.white.opacity(0.9), Color(hex: "e0f7fa")],
        startPoint: .top,
        endPoint: .bottom
    )

    static let cardBackground = Color(hex: "1e293b").opacity(0.8)
    static let glassBackground = Color.white.opacity(0.1)

    static let neonCyan = Color(hex: "00d4ff")
    static let neonPurple = Color(hex: "7c3aed")
    static let neonPink = Color(hex: "ff006e")
    static let snowWhite = Color(hex: "f0f9ff")
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
