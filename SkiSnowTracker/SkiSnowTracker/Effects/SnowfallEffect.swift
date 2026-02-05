import SwiftUI

struct SnowfallEffect: View {
    let snowflakeCount = 40

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<snowflakeCount, id: \.self) { index in
                    Snowflake(
                        containerSize: geometry.size,
                        delay: Double(index) * 0.15
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Individual Snowflake

struct Snowflake: View {
    let containerSize: CGSize
    let delay: Double

    @State private var isAnimating = false

    private let size: CGFloat
    private let startX: CGFloat
    private let duration: Double
    private let swayAmount: CGFloat
    private let opacity: Double

    init(containerSize: CGSize, delay: Double) {
        self.containerSize = containerSize
        self.delay = delay

        // Randomize snowflake properties
        self.size = CGFloat.random(in: 3...10)
        self.startX = CGFloat.random(in: 0...containerSize.width)
        self.duration = Double.random(in: 8...15)
        self.swayAmount = CGFloat.random(in: 20...60)
        self.opacity = Double.random(in: 0.3...0.8)
    }

    var body: some View {
        SnowflakeShape(complexity: Int.random(in: 1...3))
            .fill(Color.white.opacity(opacity))
            .frame(width: size, height: size)
            .position(
                x: startX + (isAnimating ? swayAmount : -swayAmount),
                y: isAnimating ? containerSize.height + 50 : -50
            )
            .animation(
                Animation
                    .linear(duration: duration)
                    .repeatForever(autoreverses: false)
                    .delay(delay),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Snowflake Shape

struct SnowflakeShape: View {
    let complexity: Int

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2

            ZStack {
                // Main arms
                ForEach(0..<6, id: \.self) { index in
                    SnowflakeArm(radius: radius, complexity: complexity)
                        .rotationEffect(.degrees(Double(index) * 60))
                        .position(center)
                }

                // Center dot
                Circle()
                    .frame(width: radius * 0.3, height: radius * 0.3)
                    .position(center)
            }
        }
    }
}

struct SnowflakeArm: View {
    let radius: CGFloat
    let complexity: Int

    var body: some View {
        Path { path in
            // Main arm
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 0, y: -radius))

            // Branches based on complexity
            if complexity >= 2 {
                // First branch
                let branch1Y = -radius * 0.4
                path.move(to: CGPoint(x: 0, y: branch1Y))
                path.addLine(to: CGPoint(x: radius * 0.25, y: branch1Y - radius * 0.15))
                path.move(to: CGPoint(x: 0, y: branch1Y))
                path.addLine(to: CGPoint(x: -radius * 0.25, y: branch1Y - radius * 0.15))
            }

            if complexity >= 3 {
                // Second branch
                let branch2Y = -radius * 0.7
                path.move(to: CGPoint(x: 0, y: branch2Y))
                path.addLine(to: CGPoint(x: radius * 0.2, y: branch2Y - radius * 0.1))
                path.move(to: CGPoint(x: 0, y: branch2Y))
                path.addLine(to: CGPoint(x: -radius * 0.2, y: branch2Y - radius * 0.1))
            }
        }
        .stroke(Color.white, lineWidth: 1)
    }
}

// MARK: - Intensive Snowfall (for powder alerts)

struct IntensiveSnowfall: View {
    let snowflakeCount = 80
    @State private var isActive = true

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<snowflakeCount, id: \.self) { index in
                    if isActive {
                        IntensiveSnowflake(
                            containerSize: geometry.size,
                            index: index
                        )
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct IntensiveSnowflake: View {
    let containerSize: CGSize
    let index: Int

    @State private var yPosition: CGFloat = 0
    @State private var xOffset: CGFloat = 0

    private let size: CGFloat
    private let startX: CGFloat
    private let speed: Double
    private let swaySpeed: Double

    init(containerSize: CGSize, index: Int) {
        self.containerSize = containerSize
        self.index = index

        self.size = CGFloat.random(in: 4...12)
        self.startX = CGFloat.random(in: 0...containerSize.width)
        self.speed = Double.random(in: 3...6)
        self.swaySpeed = Double.random(in: 1...2)
    }

    var body: some View {
        Circle()
            .fill(Color.white.opacity(Double.random(in: 0.5...0.9)))
            .frame(width: size, height: size)
            .blur(radius: size > 8 ? 1 : 0)
            .position(x: startX + xOffset, y: yPosition)
            .onAppear {
                yPosition = CGFloat.random(in: -100...containerSize.height)

                // Falling animation
                withAnimation(
                    .linear(duration: speed)
                    .repeatForever(autoreverses: false)
                ) {
                    yPosition = containerSize.height + 100
                }

                // Sway animation
                withAnimation(
                    .easeInOut(duration: swaySpeed)
                    .repeatForever(autoreverses: true)
                ) {
                    xOffset = CGFloat.random(in: -30...30)
                }
            }
    }
}

// MARK: - Wind Effect

struct WindySnowfall: View {
    let snowflakeCount = 60
    let windStrength: CGFloat // -1 to 1, negative = left, positive = right

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<snowflakeCount, id: \.self) { index in
                    WindySnowflake(
                        containerSize: geometry.size,
                        windStrength: windStrength,
                        index: index
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct WindySnowflake: View {
    let containerSize: CGSize
    let windStrength: CGFloat
    let index: Int

    @State private var position: CGPoint = .zero
    @State private var opacity: Double = 0

    private let size: CGFloat
    private let speed: Double

    init(containerSize: CGSize, windStrength: CGFloat, index: Int) {
        self.containerSize = containerSize
        self.windStrength = windStrength
        self.index = index

        self.size = CGFloat.random(in: 3...8)
        self.speed = Double.random(in: 4...8)
    }

    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: size, height: size)
            .opacity(opacity)
            .position(position)
            .onAppear {
                position = CGPoint(
                    x: CGFloat.random(in: 0...containerSize.width),
                    y: -20
                )

                withAnimation(.easeIn(duration: 0.5).delay(Double(index) * 0.1)) {
                    opacity = Double.random(in: 0.4...0.8)
                }

                withAnimation(
                    .linear(duration: speed)
                    .repeatForever(autoreverses: false)
                    .delay(Double(index) * 0.1)
                ) {
                    position = CGPoint(
                        x: position.x + (windStrength * containerSize.width * 0.5),
                        y: containerSize.height + 20
                    )
                }
            }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(hex: "1a1a2e")
        SnowfallEffect()
    }
    .ignoresSafeArea()
}
