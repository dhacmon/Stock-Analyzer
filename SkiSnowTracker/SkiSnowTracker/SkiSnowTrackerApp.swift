import SwiftUI

@main
struct SkiSnowTrackerApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
        }
    }
}

class AppState: ObservableObject {
    @Published var resortName: String {
        didSet { UserDefaults.standard.set(resortName, forKey: "resortName") }
    }
    @Published var tripDate: Date {
        didSet { UserDefaults.standard.set(tripDate, forKey: "tripDate") }
    }
    @Published var isOnboarded: Bool {
        didSet { UserDefaults.standard.set(isOnboarded, forKey: "isOnboarded") }
    }
    @Published var snowData: SnowData
    @Published var weatherForecast: [DayForecast]
    @Published var snowHistory: [SnowRecord]

    init() {
        self.resortName = UserDefaults.standard.string(forKey: "resortName") ?? ""
        self.tripDate = UserDefaults.standard.object(forKey: "tripDate") as? Date ?? Date().addingTimeInterval(7 * 24 * 60 * 60)
        self.isOnboarded = UserDefaults.standard.bool(forKey: "isOnboarded")
        self.snowData = SnowData(topDepth: 0, bottomDepth: 0, newSnow24h: 0, newSnow48h: 0)
        self.weatherForecast = []
        self.snowHistory = []
    }

    func reset() {
        resortName = ""
        tripDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        isOnboarded = false
        snowData = SnowData(topDepth: 0, bottomDepth: 0, newSnow24h: 0, newSnow48h: 0)
        weatherForecast = []
        snowHistory = []
    }
}
