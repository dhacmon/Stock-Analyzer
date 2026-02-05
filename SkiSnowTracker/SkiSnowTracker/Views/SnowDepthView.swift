import SwiftUI

struct SnowDepthView: View {
    let snowData: SnowData
    @State private var animateProgress = false
    @State private var selectedUnit: DepthUnit = .centimeters

    enum DepthUnit: String, CaseIterable {
        case centimeters = "cm"
        case inches = "in"
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "snow")
                    .font(.title3)
                    .foregroundColor(AppTheme.neonCyan)

                Text("SNOW DEPTH")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .tracking(3)
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                // Unit toggle
                Picker("Unit", selection: $selectedUnit) {
                    ForEach(DepthUnit.allCases, id: \.self) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
            }

            // Mountain visualization
            mountainVisualization

            // Fresh snow alert
            if snowData.newSnow24h > 0 {
                freshSnowAlert
            }

            // Depth bars
            HStack(spacing: 16) {
                depthBar(
                    title: "Summit",
                    depth: selectedUnit == .centimeters ? snowData.topDepth : Int(snowData.topDepthInches),
                    maxDepth: 400,
                    color: AppTheme.neonCyan,
                    icon: "arrow.up.circle.fill"
                )

                depthBar(
                    title: "Base",
                    depth: selectedUnit == .centimeters ? snowData.bottomDepth : Int(snowData.bottomDepthInches),
                    maxDepth: 250,
                    color: AppTheme.neonPurple,
                    icon: "arrow.down.circle.fill"
                )
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
                                colors: [AppTheme.neonCyan.opacity(0.2), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                animateProgress = true
            }
        }
    }

    // MARK: - Mountain Visualization

    private var mountainVisualization: some View {
        GeometryReader { geometry in
            ZStack {
                // Mountain shape
                MountainShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "334155"),
                                Color(hex: "1e293b")
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Snow cap
                MountainShape()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.9), .white.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .mask(
                        VStack {
                            Rectangle()
                                .frame(height: geometry.size.height * snowCapPercentage)
                            Spacer()
                        }
                    )

                // Depth labels on mountain
                VStack {
                    HStack {
                        Spacer()
                        depthLabel(
                            value: selectedUnit == .centimeters ? snowData.topDepth : Int(snowData.topDepthInches),
                            unit: selectedUnit.rawValue,
                            subtitle: "Summit"
                        )
                        .padding(.trailing, 20)
                        .padding(.top, 10)
                    }

                    Spacer()

                    HStack {
                        depthLabel(
                            value: selectedUnit == .centimeters ? snowData.bottomDepth : Int(snowData.bottomDepthInches),
                            unit: selectedUnit.rawValue,
                            subtitle: "Base"
                        )
                        .padding(.leading, 20)
                        .padding(.bottom, 10)
                        Spacer()
                    }
                }
            }
        }
        .frame(height: 160)
    }

    private var snowCapPercentage: CGFloat {
        let avgDepth = CGFloat(snowData.topDepth + snowData.bottomDepth) / 2
        return min(avgDepth / 300, 0.7)
    }

    private func depthLabel(value: Int, unit: String, subtitle: String) -> some View {
        VStack(alignment: .center, spacing: 2) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text("\(value)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(unit)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }

            Text(subtitle)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.4))
                .blur(radius: 1)
        )
    }

    // MARK: - Fresh Snow Alert

    private var freshSnowAlert: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.neonCyan.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundColor(AppTheme.neonCyan)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("FRESH POWDER!")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.neonCyan)

                Text("\(formattedNewSnow) in the last 24 hours")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()

            // Snow emoji stack
            Text("  ")
                .font(.title)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.neonCyan.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.neonCyan.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private var formattedNewSnow: String {
        if selectedUnit == .centimeters {
            return "\(snowData.newSnow24h)cm"
        } else {
            return String(format: "%.1f\"", snowData.newSnow24hInches)
        }
    }

    // MARK: - Depth Bar

    private func depthBar(title: String, depth: Int, maxDepth: Int, color: Color, icon: String) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)

                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white.opacity(0.7))
            }

            ZStack(alignment: .bottom) {
                // Background bar
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 60)

                // Progress bar
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.6), color],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(
                        width: 60,
                        height: animateProgress ? CGFloat(min(depth, maxDepth)) / CGFloat(maxDepth) * 80 : 0
                    )
                    .shadow(color: color.opacity(0.5), radius: 8)
            }
            .frame(height: 80)

            Text("\(depth)\(selectedUnit.rawValue)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Mountain Shape

struct MountainShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.midX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX - 20, y: rect.maxY))
        path.addLine(to: CGPoint(x: 20, y: rect.maxY))
        path.closeSubpath()

        // Second smaller peak
        path.move(to: CGPoint(x: rect.maxX * 0.75, y: rect.maxY * 0.3))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX * 0.5, y: rect.maxY))
        path.closeSubpath()

        return path
    }
}

// MARK: - Snow History Chart

struct SnowHistoryChart: View {
    let history: [SnowRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(AppTheme.neonPurple)

                Text("SNOW HISTORY")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .tracking(3)
                    .foregroundColor(.white.opacity(0.7))

                Spacer()
            }

            if history.isEmpty {
                Text("Tracking snow depth over time...")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                // Simple bar chart
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(history.suffix(7)) { record in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [AppTheme.neonCyan, AppTheme.neonPurple],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(width: 30, height: CGFloat(record.topDepth) / 4)

                            Text(dayLabel(for: record.date))
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
                .frame(height: 100)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardBackground)
        )
    }

    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

#Preview {
    ZStack {
        AnimatedBackground()

        ScrollView {
            VStack(spacing: 20) {
                SnowDepthView(snowData: SnowData(
                    topDepth: 245,
                    bottomDepth: 120,
                    newSnow24h: 25,
                    newSnow48h: 40
                ))

                SnowHistoryChart(history: [])
            }
            .padding()
        }
    }
}
