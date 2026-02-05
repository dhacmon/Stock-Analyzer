import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else if !appState.isOnboarded {
                OnboardingView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                DashboardView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showSplash)
        .animation(.easeInOut(duration: 0.5), value: appState.isOnboarded)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    showSplash = false
                }
            }
        }
    }
}

// MARK: - Splash View

struct SplashView: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0
    @State private var snowflakeOffset: CGFloat = -100

    var body: some View {
        ZStack {
            AnimatedBackground()

            SnowfallEffect()

            VStack(spacing: 30) {
                ZStack {
                    // Glow effect
                    Image(systemName: "snowflake")
                        .font(.system(size: 120, weight: .thin))
                        .foregroundStyle(AppTheme.neonCyan)
                        .blur(radius: 20)
                        .opacity(0.6)

                    Image(systemName: "snowflake")
                        .font(.system(size: 100, weight: .thin))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.neonCyan, AppTheme.neonPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(rotation))
                }
                .scaleEffect(scale)

                VStack(spacing: 8) {
                    Text("POWDER")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.accentGradient)

                    Text("TRACKER")
                        .font(.system(size: 28, weight: .light, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .tracking(12)
                }
                .opacity(opacity)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                scale = 1.0
            }
            withAnimation(.easeInOut(duration: 0.8).delay(0.3)) {
                opacity = 1.0
            }
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
