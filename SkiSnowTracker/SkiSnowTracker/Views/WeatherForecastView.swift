import SwiftUI

struct WeatherForecastView: View {
    let forecast: [DayForecast]
    @State private var selectedDay: DayForecast?
    @State private var showDetail = false

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "cloud.sun.fill")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Text("7-DAY FORECAST")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .tracking(3)
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                if !forecast.isEmpty {
                    Text("Updated now")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))
                }
            }

            if forecast.isEmpty {
                emptyForecastView
            } else {
                // Horizontal scrolling forecast
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(forecast.enumerated()), id: \.element.id) { index, day in
                            ForecastDayCard(
                                day: day,
                                isToday: index == 0,
                                isSelected: selectedDay?.id == day.id
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3)) {
                                    if selectedDay?.id == day.id {
                                        selectedDay = nil
                                    } else {
                                        selectedDay = day
                                    }
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }

                // Expanded detail view
                if let day = selectedDay {
                    ForecastDetailView(day: day)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.9).combined(with: .opacity),
                            removal: .scale(scale: 0.9).combined(with: .opacity)
                        ))
                }

                // Snow probability summary
                snowProbabilitySummary
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [.yellow.opacity(0.2), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }

    // MARK: - Empty State

    private var emptyForecastView: some View {
        VStack(spacing: 16) {
            Image(systemName: "cloud.fill")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.3))

            Text("Loading forecast...")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.5))

            ProgressView()
                .tint(AppTheme.neonCyan)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    // MARK: - Snow Probability Summary

    private var snowProbabilitySummary: some View {
        let snowDays = forecast.filter { $0.snowfallChance >= 50 }
        let totalExpectedSnow = forecast.reduce(0) { $0 + $1.expectedSnowfall }

        return HStack(spacing: 20) {
            summaryItem(
                value: "\(snowDays.count)",
                label: "Snow Days",
                icon: "cloud.snow.fill",
                color: AppTheme.neonCyan
            )

            Divider()
                .frame(height: 40)
                .background(Color.white.opacity(0.2))

            summaryItem(
                value: "\(totalExpectedSnow)cm",
                label: "Expected",
                icon: "snow",
                color: AppTheme.neonPurple
            )

            Divider()
                .frame(height: 40)
                .background(Color.white.opacity(0.2))

            summaryItem(
                value: averageTemp,
                label: "Avg Temp",
                icon: "thermometer.medium",
                color: .orange
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.glassBackground)
        )
    }

    private var averageTemp: String {
        guard !forecast.isEmpty else { return "--" }
        let avg = forecast.reduce(0) { $0 + $1.highTemp } / forecast.count
        return "\(avg)°"
    }

    private func summaryItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Forecast Day Card

struct ForecastDayCard: View {
    let day: DayForecast
    let isToday: Bool
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Day label
            Text(dayLabel)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isToday ? AppTheme.neonCyan : .white.opacity(0.6))

            // Weather icon
            ZStack {
                Circle()
                    .fill(day.condition.color.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: day.condition.icon)
                    .font(.title2)
                    .foregroundStyle(day.condition.color)
                    .symbolEffect(.pulse, options: .repeating, value: day.condition == .heavySnow || day.condition == .blizzard)
            }

            // Temperature
            VStack(spacing: 2) {
                Text("\(day.highTemp)°")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("\(day.lowTemp)°")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
            }

            // Snow indicator
            if day.snowfallChance > 30 {
                HStack(spacing: 2) {
                    Image(systemName: "snow")
                        .font(.system(size: 10))

                    Text("\(day.snowfallChance)%")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(AppTheme.neonCyan)
            }
        }
        .frame(width: 70)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isSelected ? AppTheme.neonCyan.opacity(0.15) : AppTheme.glassBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected ? AppTheme.neonCyan.opacity(0.5) : Color.clear,
                            lineWidth: 1
                        )
                )
        )
        .overlay(
            isToday ?
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.neonCyan, lineWidth: 2)
            : nil
        )
    }

    private var dayLabel: String {
        if isToday { return "TODAY" }

        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: day.date).uppercased()
    }
}

// MARK: - Forecast Detail View

struct ForecastDetailView: View {
    let day: DayForecast

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(fullDateLabel)
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(day.condition.description)
                        .font(.subheadline)
                        .foregroundColor(day.condition.color)
                }

                Spacer()

                Image(systemName: day.condition.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(day.condition.color)
            }

            Divider()
                .background(Color.white.opacity(0.2))

            HStack(spacing: 0) {
                detailItem(icon: "thermometer.high", value: "\(day.highTemp)°", label: "High")
                detailItem(icon: "thermometer.low", value: "\(day.lowTemp)°", label: "Low")
                detailItem(icon: "wind", value: "\(day.windSpeed) km/h", label: "Wind")
                detailItem(icon: "snow", value: "\(day.expectedSnowfall)cm", label: "Snow")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.glassBackground)
        )
    }

    private var fullDateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: day.date)
    }

    private func detailItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.6))

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ZStack {
        AnimatedBackground()

        ScrollView {
            WeatherForecastView(forecast: [
                DayForecast(date: Date(), highTemp: -2, lowTemp: -8, condition: .heavySnow, snowfallChance: 90, expectedSnowfall: 25, windSpeed: 15),
                DayForecast(date: Date().addingTimeInterval(86400), highTemp: -1, lowTemp: -6, condition: .lightSnow, snowfallChance: 60, expectedSnowfall: 10, windSpeed: 10),
                DayForecast(date: Date().addingTimeInterval(86400 * 2), highTemp: 2, lowTemp: -3, condition: .partlyCloudy, snowfallChance: 20, expectedSnowfall: 0, windSpeed: 8),
                DayForecast(date: Date().addingTimeInterval(86400 * 3), highTemp: 1, lowTemp: -5, condition: .cloudy, snowfallChance: 40, expectedSnowfall: 5, windSpeed: 12),
                DayForecast(date: Date().addingTimeInterval(86400 * 4), highTemp: -3, lowTemp: -10, condition: .blizzard, snowfallChance: 95, expectedSnowfall: 40, windSpeed: 35),
                DayForecast(date: Date().addingTimeInterval(86400 * 5), highTemp: 0, lowTemp: -4, condition: .sunny, snowfallChance: 5, expectedSnowfall: 0, windSpeed: 5),
                DayForecast(date: Date().addingTimeInterval(86400 * 6), highTemp: 3, lowTemp: -2, condition: .sunny, snowfallChance: 0, expectedSnowfall: 0, windSpeed: 8),
            ])
            .padding()
        }
    }
}
