import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentStep = 0
    @State private var resortInput = ""
    @State private var selectedDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
    @State private var showResortSuggestions = false
    @State private var animateIn = false

    var filteredResorts: [SkiResort] {
        if resortInput.isEmpty {
            return SkiResort.popular
        }
        return SkiResort.popular.filter {
            $0.name.localizedCaseInsensitiveContains(resortInput)
        }
    }

    var body: some View {
        ZStack {
            AnimatedBackground()
            SnowfallEffect()

            VStack(spacing: 0) {
                // Progress indicator
                HStack(spacing: 12) {
                    ForEach(0..<3) { index in
                        Capsule()
                            .fill(index <= currentStep ? AppTheme.neonCyan : Color.white.opacity(0.3))
                            .frame(width: index == currentStep ? 40 : 20, height: 4)
                            .animation(.spring(response: 0.4), value: currentStep)
                    }
                }
                .padding(.top, 60)
                .padding(.bottom, 40)

                // Content
                TabView(selection: $currentStep) {
                    welcomeStep.tag(0)
                    resortStep.tag(1)
                    dateStep.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animateIn = true
            }
        }
    }

    // MARK: - Welcome Step

    private var welcomeStep: some View {
        VStack(spacing: 30) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppTheme.neonCyan.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .blur(radius: 40)

                Image(systemName: "mountain.2.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.neonCyan, AppTheme.neonPurple],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: AppTheme.neonCyan.opacity(0.5), radius: 20)
            }
            .scaleEffect(animateIn ? 1 : 0.5)
            .opacity(animateIn ? 1 : 0)

            VStack(spacing: 16) {
                Text("Welcome to")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.7))

                Text("Powder Tracker")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.accentGradient)

                Text("Track snow conditions at your favorite resort\nand never miss a powder day!")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .offset(y: animateIn ? 0 : 30)
            .opacity(animateIn ? 1 : 0)

            Spacer()

            modernButton(title: "Get Started", icon: "arrow.right") {
                withAnimation(.spring(response: 0.4)) {
                    currentStep = 1
                }
            }
            .padding(.bottom, 60)
        }
    }

    // MARK: - Resort Step

    private var resortStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Where are you skiing?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Enter your resort name")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.top, 40)

            // Search field
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.neonCyan)

                TextField("Search resorts...", text: $resortInput)
                    .foregroundColor(.white)
                    .autocorrectionDisabled()

                if !resortInput.isEmpty {
                    Button {
                        resortInput = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.neonCyan.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 24)

            // Resort suggestions
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredResorts) { resort in
                        resortCard(resort: resort)
                    }
                }
                .padding(.horizontal, 24)
            }
            .frame(maxHeight: 350)

            Spacer()

            HStack(spacing: 16) {
                Button {
                    withAnimation(.spring(response: 0.4)) {
                        currentStep = 0
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 50, height: 50)
                        .background(AppTheme.glassBackground)
                        .clipShape(Circle())
                }

                modernButton(title: "Continue", icon: "arrow.right", disabled: resortInput.isEmpty) {
                    withAnimation(.spring(response: 0.4)) {
                        currentStep = 2
                    }
                }
            }
            .padding(.bottom, 60)
        }
    }

    private func resortCard(resort: SkiResort) -> some View {
        Button {
            resortInput = resort.name
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(resortInput == resort.name ? AppTheme.neonCyan.opacity(0.2) : AppTheme.glassBackground)
                        .frame(width: 50, height: 50)

                    Image(systemName: "mountain.2.fill")
                        .foregroundColor(resortInput == resort.name ? AppTheme.neonCyan : .white.opacity(0.6))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(resort.name)
                        .font(.headline)
                        .foregroundColor(.white)

                    HStack(spacing: 8) {
                        Label("\(resort.country)", systemImage: "mappin")
                        Label("\(resort.trails) trails", systemImage: "arrow.down.right")
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                if resortInput == resort.name {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.neonCyan)
                        .font(.title2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(resortInput == resort.name ? AppTheme.neonCyan.opacity(0.1) : AppTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(resortInput == resort.name ? AppTheme.neonCyan.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Date Step

    private var dateStep: some View {
        VStack(spacing: 30) {
            VStack(spacing: 8) {
                Text("When's your trip?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("We'll count down the days!")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.top, 40)

            // Selected resort display
            HStack(spacing: 12) {
                Image(systemName: "mountain.2.fill")
                    .foregroundColor(AppTheme.neonCyan)

                Text(resortInput)
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.4)) {
                        currentStep = 1
                    }
                } label: {
                    Text("Change")
                        .font(.caption)
                        .foregroundColor(AppTheme.neonCyan)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.glassBackground)
            )
            .padding(.horizontal, 24)

            // Date picker
            VStack(spacing: 16) {
                DatePicker(
                    "Trip Date",
                    selection: $selectedDate,
                    in: Date()...,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .tint(AppTheme.neonCyan)
                .colorScheme(.dark)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(AppTheme.cardBackground)
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            HStack(spacing: 16) {
                Button {
                    withAnimation(.spring(response: 0.4)) {
                        currentStep = 1
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 50, height: 50)
                        .background(AppTheme.glassBackground)
                        .clipShape(Circle())
                }

                modernButton(title: "Start Tracking", icon: "snowflake") {
                    completeOnboarding()
                }
            }
            .padding(.bottom, 60)
        }
    }

    // MARK: - Components

    private func modernButton(title: String, icon: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.headline)

                Image(systemName: icon)
                    .font(.headline)
            }
            .foregroundColor(disabled ? .white.opacity(0.5) : .white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(disabled ? AppTheme.glassBackground : AppTheme.neonCyan)
                    .shadow(color: disabled ? .clear : AppTheme.neonCyan.opacity(0.5), radius: 10, y: 5)
            )
        }
        .disabled(disabled)
        .padding(.horizontal, 24)
    }

    // MARK: - Actions

    private func completeOnboarding() {
        appState.resortName = resortInput
        appState.tripDate = selectedDate
        appState.isOnboarded = true

        // Request notification permissions
        NotificationService.shared.requestPermission { _ in }

        // Load initial data
        Task {
            await SnowService.shared.fetchSnowData(for: resortInput, appState: appState)
            await SnowService.shared.fetchWeatherForecast(for: resortInput, appState: appState)
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
