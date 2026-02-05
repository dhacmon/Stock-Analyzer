import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSettings = false
    @State private var isRefreshing = false
    @State private var showPowderAlert = false
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Animated background
            AnimatedBackground()

            // Snowfall effect
            SnowfallEffect()

            // Main content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    headerView
                        .padding(.top, 60)

                    // Countdown timer
                    CountdownView(targetDate: appState.tripDate)
                        .padding(.horizontal)

                    // Snow depth card
                    SnowDepthView(snowData: appState.snowData)
                        .padding(.horizontal)

                    // Weather forecast
                    WeatherForecastView(forecast: appState.weatherForecast)
                        .padding(.horizontal)

                    // Quick stats
                    quickStatsView
                        .padding(.horizontal)

                    // Snow history
                    SnowHistoryChart(history: appState.snowHistory)
                        .padding(.horizontal)

                    // Bottom spacing
                    Spacer()
                        .frame(height: 100)
                }
            }
            .refreshable {
                await refreshData()
            }

            // Floating action button
            VStack {
                Spacer()

                HStack {
                    Spacer()

                    Menu {
                        Button {
                            Task { await refreshData() }
                        } label: {
                            Label("Refresh Data", systemImage: "arrow.clockwise")
                        }

                        Button {
                            shareConditions()
                        } label: {
                            Label("Share Conditions", systemImage: "square.and.arrow.up")
                        }

                        Divider()

                        Button {
                            showSettings = true
                        } label: {
                            Label("Settings", systemImage: "gear")
                        }

                        Button(role: .destructive) {
                            appState.reset()
                        } label: {
                            Label("Reset App", systemImage: "trash")
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [AppTheme.neonCyan, AppTheme.neonPurple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 56, height: 56)
                                .shadow(color: AppTheme.neonCyan.opacity(0.5), radius: 10, y: 5)

                            Image(systemName: "ellipsis")
                                .font(.title2.weight(.semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 24)
                }
            }

            // Loading overlay
            if isRefreshing {
                loadingOverlay
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(appState)
        }
        .alert("POWDER ALERT!", isPresented: $showPowderAlert) {
            Button("Let's Go!") { }
        } message: {
            Text("\(appState.snowData.newSnow24h)cm of fresh snow at \(appState.resortName)!")
        }
        .onAppear {
            // Check for powder conditions
            if appState.snowData.newSnow24h >= 20 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    showPowderAlert = true
                }
            }
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "mountain.2.fill")
                        .foregroundColor(AppTheme.neonCyan)

                    Text(appState.resortName)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Text(tripDateFormatted)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            // Notification bell
            Button {
                NotificationService.shared.requestPermission { granted in
                    if granted {
                        NotificationService.shared.scheduleDailySnowUpdate(resortName: appState.resortName)
                        NotificationService.shared.scheduleTripCountdownNotification(
                            resortName: appState.resortName,
                            tripDate: appState.tripDate
                        )
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(AppTheme.glassBackground)
                        .frame(width: 44, height: 44)

                    Image(systemName: NotificationService.shared.isAuthorized ? "bell.fill" : "bell")
                        .foregroundColor(NotificationService.shared.isAuthorized ? AppTheme.neonCyan : .white.opacity(0.6))
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private var tripDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return "Trip: \(formatter.string(from: appState.tripDate))"
    }

    // MARK: - Quick Stats

    private var quickStatsView: some View {
        HStack(spacing: 12) {
            quickStatCard(
                title: "Fresh Snow",
                value: "\(appState.snowData.newSnow24h)cm",
                subtitle: "Last 24h",
                icon: "snowflake",
                color: AppTheme.neonCyan
            )

            quickStatCard(
                title: "48h Total",
                value: "\(appState.snowData.newSnow48h)cm",
                subtitle: "New snow",
                icon: "cloud.snow.fill",
                color: AppTheme.neonPurple
            )

            quickStatCard(
                title: "Conditions",
                value: conditionsRating,
                subtitle: "Overall",
                icon: conditionsIcon,
                color: conditionsColor
            )
        }
    }

    private var conditionsRating: String {
        let total = appState.snowData.topDepth + appState.snowData.newSnow24h
        switch total {
        case 0..<100: return "Fair"
        case 100..<200: return "Good"
        case 200..<300: return "Great"
        default: return "Epic!"
        }
    }

    private var conditionsIcon: String {
        let total = appState.snowData.topDepth + appState.snowData.newSnow24h
        switch total {
        case 0..<100: return "hand.thumbsup"
        case 100..<200: return "star.fill"
        case 200..<300: return "star.circle.fill"
        default: return "sparkles"
        }
    }

    private var conditionsColor: Color {
        let total = appState.snowData.topDepth + appState.snowData.newSnow24h
        switch total {
        case 0..<100: return .orange
        case 100..<200: return .yellow
        case 200..<300: return .green
        default: return AppTheme.neonCyan
        }
    }

    private func quickStatCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))

                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(AppTheme.neonCyan)

                Text("Updating conditions...")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.cardBackground)
            )
        }
    }

    // MARK: - Actions

    private func refreshData() async {
        isRefreshing = true
        await SnowService.shared.refreshAllData(for: appState.resortName, appState: appState)
        isRefreshing = false

        // Check for powder alert
        if appState.snowData.newSnow24h >= 20 {
            showPowderAlert = true
        }
    }

    private func shareConditions() {
        let text = """
        Snow Report for \(appState.resortName)!

        Summit: \(appState.snowData.topDepth)cm
        Base: \(appState.snowData.bottomDepth)cm
        Fresh Snow (24h): \(appState.snowData.newSnow24h)cm

        Conditions: \(conditionsRating)

        Tracked with Powder Tracker
        """

        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var notificationsEnabled = NotificationService.shared.isAuthorized
    @State private var dailyUpdateTime = Date()

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.primaryGradient
                    .ignoresSafeArea()

                List {
                    Section {
                        HStack {
                            Label("Resort", systemImage: "mountain.2.fill")
                            Spacer()
                            Text(appState.resortName)
                                .foregroundColor(.secondary)
                        }

                        DatePicker(
                            "Trip Date",
                            selection: Binding(
                                get: { appState.tripDate },
                                set: { appState.tripDate = $0 }
                            ),
                            displayedComponents: .date
                        )
                    } header: {
                        Text("Trip Details")
                    }

                    Section {
                        Toggle(isOn: $notificationsEnabled) {
                            Label("Push Notifications", systemImage: "bell.fill")
                        }
                        .onChange(of: notificationsEnabled) { _, newValue in
                            if newValue {
                                NotificationService.shared.requestPermission { _ in }
                            }
                        }

                        if notificationsEnabled {
                            DatePicker(
                                "Daily Update Time",
                                selection: $dailyUpdateTime,
                                displayedComponents: .hourAndMinute
                            )
                        }
                    } header: {
                        Text("Notifications")
                    } footer: {
                        Text("Get notified about fresh powder and storm alerts!")
                    }

                    Section {
                        Button {
                            appState.reset()
                            dismiss()
                        } label: {
                            Label("Change Resort", systemImage: "arrow.triangle.2.circlepath")
                        }

                        Button(role: .destructive) {
                            NotificationService.shared.cancelAllNotifications()
                            appState.reset()
                            dismiss()
                        } label: {
                            Label("Reset All Data", systemImage: "trash")
                        }
                    } header: {
                        Text("Data")
                    }

                    Section {
                        Link(destination: URL(string: "https://github.com")!) {
                            Label("Source Code", systemImage: "chevron.left.forwardslash.chevron.right")
                        }

                        HStack {
                            Label("Version", systemImage: "info.circle")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.secondary)
                        }
                    } header: {
                        Text("About")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.neonCyan)
                }
            }
        }
    }
}

#Preview {
    let appState = AppState()
    appState.resortName = "Whistler Blackcomb"
    appState.tripDate = Date().addingTimeInterval(10 * 24 * 60 * 60)
    appState.isOnboarded = true
    appState.snowData = SnowData(topDepth: 245, bottomDepth: 120, newSnow24h: 25, newSnow48h: 40)
    appState.weatherForecast = [
        DayForecast(date: Date(), highTemp: -2, lowTemp: -8, condition: .heavySnow, snowfallChance: 90, expectedSnowfall: 25, windSpeed: 15),
        DayForecast(date: Date().addingTimeInterval(86400), highTemp: -1, lowTemp: -6, condition: .lightSnow, snowfallChance: 60, expectedSnowfall: 10, windSpeed: 10),
        DayForecast(date: Date().addingTimeInterval(86400 * 2), highTemp: 2, lowTemp: -3, condition: .partlyCloudy, snowfallChance: 20, expectedSnowfall: 0, windSpeed: 8),
        DayForecast(date: Date().addingTimeInterval(86400 * 3), highTemp: 1, lowTemp: -5, condition: .cloudy, snowfallChance: 40, expectedSnowfall: 5, windSpeed: 12),
        DayForecast(date: Date().addingTimeInterval(86400 * 4), highTemp: -3, lowTemp: -10, condition: .blizzard, snowfallChance: 95, expectedSnowfall: 40, windSpeed: 35),
        DayForecast(date: Date().addingTimeInterval(86400 * 5), highTemp: 0, lowTemp: -4, condition: .sunny, snowfallChance: 5, expectedSnowfall: 0, windSpeed: 5),
        DayForecast(date: Date().addingTimeInterval(86400 * 6), highTemp: 3, lowTemp: -2, condition: .sunny, snowfallChance: 0, expectedSnowfall: 0, windSpeed: 8),
    ]

    return DashboardView()
        .environmentObject(appState)
}
