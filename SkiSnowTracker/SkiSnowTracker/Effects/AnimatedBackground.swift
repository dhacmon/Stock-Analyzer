import SwiftUI

struct AnimatedBackground: View {
    @State private var animateGradient = false
    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(hex: "0f0c29"),
                    Color(hex: "302b63"),
                    Color(hex: "24243e")
                ],
                startPoint: animateGradient ? .topLeading : .bottomLeading,
                endPoint: animateGradient ? .bottomTrailing : .topTrailing
            )
            .animation(
                .easeInOut(duration: 8)
                .repeatForever(autoreverses: true),
                value: animateGradient
            )

            // Aurora effect
            GeometryReader { geometry in
                ZStack {
                    // First aurora wave
                    AuroraWave(
                        color: AppTheme.neonCyan.opacity(0.3),
                        amplitude: 50,
                        frequency: 1.5,
                        phase: phase
                    )
                    .frame(height: 200)
                    .position(x: geometry.size.width / 2, y: geometry.size.height * 0.2)
                    .blur(radius: 30)

                    // Second aurora wave
                    AuroraWave(
                        color: AppTheme.neonPurple.opacity(0.25),
                        amplitude: 40,
                        frequency: 2,
                        phase: phase + 1
                    )
                    .frame(height: 180)
                    .position(x: geometry.size.width / 2, y: geometry.size.height * 0.3)
                    .blur(radius: 40)

                    // Third aurora wave
                    AuroraWave(
                        color: Color(hex: "00ff88").opacity(0.15),
                        amplitude: 60,
                        frequency: 1,
                        phase: phase + 2
                    )
                    .frame(height: 150)
                    .position(x: geometry.size.width / 2, y: geometry.size.height * 0.15)
                    .blur(radius: 50)
                }
            }

            // Floating orbs
            floatingOrbs

            // Star field
            StarField()
                .opacity(0.6)

            // Gradient overlay for depth
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
        .onAppear {
            animateGradient = true
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }

    // MARK: - Floating Orbs

    private var floatingOrbs: some View {
        GeometryReader { geometry in
            ZStack {
                FloatingOrb(
                    color: AppTheme.neonCyan,
                    size: 100,
                    startPosition: CGPoint(x: geometry.size.width * 0.2, y: geometry.size.height * 0.3),
                    moveRange: 50
                )
                .blur(radius: 40)
                .opacity(0.4)

                FloatingOrb(
                    color: AppTheme.neonPurple,
                    size: 120,
                    startPosition: CGPoint(x: geometry.size.width * 0.8, y: geometry.size.height * 0.6),
                    moveRange: 60
                )
                .blur(radius: 50)
                .opacity(0.3)

                FloatingOrb(
                    color: AppTheme.neonPink,
                    size: 80,
                    startPosition: CGPoint(x: geometry.size.width * 0.5, y: geometry.size.height * 0.8),
                    moveRange: 40
                )
                .blur(radius: 35)
                .opacity(0.25)
            }
        }
    }
}

// MARK: - Aurora Wave

struct AuroraWave: View {
    let color: Color
    let amplitude: CGFloat
    let frequency: CGFloat
    let phase: CGFloat

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let midHeight = height / 2

                path.move(to: CGPoint(x: 0, y: midHeight))

                for x in stride(from: 0, through: width, by: 2) {
                    let relativeX = x / width
                    let sine = sin((relativeX * frequency * .pi * 2) + phase)
                    let y = midHeight + (sine * amplitude)
                    path.addLine(to: CGPoint(x: x, y: y))
                }

                path.addLine(to: CGPoint(x: width, y: height))
                path.addLine(to: CGPoint(x: 0, y: height))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [color, color.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
}

// MARK: - Floating Orb

struct FloatingOrb: View {
    let color: Color
    let size: CGFloat
    let startPosition: CGPoint
    let moveRange: CGFloat

    @State private var offset: CGSize = .zero

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color, color.opacity(0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: size / 2
                )
            )
            .frame(width: size, height: size)
            .position(startPosition)
            .offset(offset)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: Double.random(in: 4...8))
                    .repeatForever(autoreverses: true)
                ) {
                    offset = CGSize(
                        width: CGFloat.random(in: -moveRange...moveRange),
                        height: CGFloat.random(in: -moveRange...moveRange)
                    )
                }
            }
    }
}

// MARK: - Star Field

struct StarField: View {
    let starCount = 50

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<starCount, id: \.self) { index in
                    Star(size: CGFloat.random(in: 1...3))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height * 0.6)
                        )
                }
            }
        }
    }
}

struct Star: View {
    let size: CGFloat
    @State private var opacity: Double = 0.3

    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: size, height: size)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: Double.random(in: 1...3))
                    .repeatForever(autoreverses: true)
                    .delay(Double.random(in: 0...2))
                ) {
                    opacity = Double.random(in: 0.5...1.0)
                }
            }
    }
}

// MARK: - Mountain Silhouette Background

struct MountainSilhouette: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Back mountains
                MountainLayer(
                    peaks: [0.3, 0.5, 0.35, 0.45, 0.4],
                    color: Color(hex: "1a1a2e").opacity(0.8)
                )
                .offset(y: geometry.size.height * 0.1)

                // Front mountains
                MountainLayer(
                    peaks: [0.25, 0.4, 0.3, 0.5, 0.35],
                    color: Color(hex: "0f0f1a").opacity(0.9)
                )
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }
}

struct MountainLayer: View {
    let peaks: [CGFloat]
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let segmentWidth = width / CGFloat(peaks.count - 1)

                path.move(to: CGPoint(x: 0, y: height))

                for (index, peak) in peaks.enumerated() {
                    let x = CGFloat(index) * segmentWidth
                    let y = height * (1 - peak)

                    if index == 0 {
                        path.addLine(to: CGPoint(x: x, y: y))
                    } else {
                        let prevX = CGFloat(index - 1) * segmentWidth
                        let controlX = (prevX + x) / 2

                        path.addQuadCurve(
                            to: CGPoint(x: x, y: y),
                            control: CGPoint(x: controlX, y: y - 20)
                        )
                    }
                }

                path.addLine(to: CGPoint(x: width, y: height))
                path.closeSubpath()
            }
            .fill(color)
        }
    }
}

#Preview {
    AnimatedBackground()
}
