import SwiftUI

struct CountdownView: View {
    let targetDate: Date
    @State private var countdown: CountdownComponents = CountdownComponents(days: 0, hours: 0, minutes: 0, seconds: 0)
    @State private var timer: Timer?
    @State private var pulseAnimation = false

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "timer")
                    .font(.title3)
                    .foregroundColor(AppTheme.neonCyan)

                Text("COUNTDOWN")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .tracking(3)
                    .foregroundColor(.white.opacity(0.7))

                Spacer()
            }

            // Main countdown display
            HStack(spacing: 12) {
                countdownUnit(value: countdown.days, label: "DAYS", isPrimary: true)
                separatorDots
                countdownUnit(value: countdown.hours, label: "HRS")
                separatorDots
                countdownUnit(value: countdown.minutes, label: "MIN")
                separatorDots
                countdownUnit(value: countdown.seconds, label: "SEC")
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.neonCyan, AppTheme.neonPurple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: progressWidth(totalWidth: geometry.size.width), height: 6)
                        .shadow(color: AppTheme.neonCyan.opacity(0.5), radius: 4)
                }
            }
            .frame(height: 6)

            // Excitement message
            excitementMessage
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [AppTheme.neonCyan.opacity(0.3), AppTheme.neonPurple.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .onAppear {
            updateCountdown()
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    // MARK: - Countdown Unit

    private func countdownUnit(value: Int, label: String, isPrimary: Bool = false) -> some View {
        VStack(spacing: 6) {
            Text(String(format: "%02d", value))
                .font(.system(size: isPrimary ? 44 : 28, weight: .bold, design: .rounded))
                .foregroundStyle(
                    isPrimary ?
                    AnyShapeStyle(LinearGradient(
                        colors: [AppTheme.neonCyan, AppTheme.neonPurple],
                        startPoint: .top,
                        endPoint: .bottom
                    )) :
                    AnyShapeStyle(Color.white)
                )
                .shadow(color: isPrimary ? AppTheme.neonCyan.opacity(0.5) : .clear, radius: 10)
                .scaleEffect(pulseAnimation && isPrimary ? 1.05 : 1.0)

            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .tracking(2)
        }
        .frame(minWidth: isPrimary ? 70 : 44)
    }

    private var separatorDots: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(AppTheme.neonCyan.opacity(0.6))
                .frame(width: 4, height: 4)
            Circle()
                .fill(AppTheme.neonCyan.opacity(0.6))
                .frame(width: 4, height: 4)
        }
        .offset(y: -10)
    }

    // MARK: - Excitement Message

    @ViewBuilder
    private var excitementMessage: some View {
        let message = getExcitementMessage()

        HStack(spacing: 8) {
            Image(systemName: message.icon)
                .foregroundColor(message.color)

            Text(message.text)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(
            Capsule()
                .fill(message.color.opacity(0.15))
        )
    }

    private func getExcitementMessage() -> (text: String, icon: String, color: Color) {
        switch countdown.days {
        case 0:
            return ("IT'S POWDER DAY!", "snowflake", AppTheme.neonCyan)
        case 1:
            return ("TOMORROW! Get ready!", "bolt.fill", .yellow)
        case 2...3:
            return ("Almost there! Pack your gear!", "bag.fill", .orange)
        case 4...7:
            return ("One week to go!", "calendar", AppTheme.neonPurple)
        case 8...14:
            return ("Two weeks until shred time!", "figure.skiing.downhill", .green)
        default:
            return ("The mountain awaits!", "mountain.2.fill", .blue)
        }
    }

    // MARK: - Progress Calculation

    private func progressWidth(totalWidth: CGFloat) -> CGFloat {
        let totalSeconds = targetDate.timeIntervalSince(Date())
        let maxSeconds: TimeInterval = 90 * 24 * 60 * 60 // 90 days max

        if totalSeconds <= 0 {
            return totalWidth
        }

        let progress = 1 - min(totalSeconds / maxSeconds, 1)
        return totalWidth * CGFloat(progress)
    }

    // MARK: - Timer Logic

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                updateCountdown()
            }

            // Pulse animation every second
            withAnimation(.easeInOut(duration: 0.5)) {
                pulseAnimation = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    pulseAnimation = false
                }
            }
        }
    }

    private func updateCountdown() {
        countdown = CountdownComponents.from(date: targetDate)
    }
}

// MARK: - Compact Countdown View

struct CompactCountdownView: View {
    let targetDate: Date
    @State private var countdown: CountdownComponents = CountdownComponents(days: 0, hours: 0, minutes: 0, seconds: 0)
    @State private var timer: Timer?

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "timer")
                .font(.title2)
                .foregroundColor(AppTheme.neonCyan)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(countdown.days) days to go")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("\(countdown.hours)h \(countdown.minutes)m \(countdown.seconds)s")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .monospacedDigit()
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.glassBackground)
        )
        .onAppear {
            updateCountdown()
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            updateCountdown()
        }
    }

    private func updateCountdown() {
        countdown = CountdownComponents.from(date: targetDate)
    }
}

#Preview {
    ZStack {
        AnimatedBackground()

        VStack(spacing: 20) {
            CountdownView(targetDate: Date().addingTimeInterval(5 * 24 * 60 * 60))
            CompactCountdownView(targetDate: Date().addingTimeInterval(5 * 24 * 60 * 60))
        }
        .padding()
    }
}
