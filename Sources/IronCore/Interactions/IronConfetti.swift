import SwiftUI

// MARK: - IronConfettiModifier

/// A confetti celebration effect.
///
/// Creates a burst of colorful particles to celebrate completing
/// important tasks, like wallet backup in Family. Automatically uses
/// theme-derived colors when no custom colors are provided, and respects
/// the Reduce Motion accessibility setting.
///
/// ## Basic Usage
///
/// ```swift
/// @State private var celebrate = false
///
/// VStack {
///   Button("Complete!") {
///     celebrate = true
///   }
/// }
/// .ironConfetti(isActive: $celebrate)
/// ```
///
/// ## Customization
///
/// ```swift
/// .ironConfetti(
///   isActive: $celebrate,
///   colors: [.red, .pink, .purple],
///   particleCount: 100
/// )
/// ```
public struct IronConfettiModifier: ViewModifier {

  // MARK: Lifecycle

  /// Creates a confetti modifier.
  ///
  /// - Parameters:
  ///   - isActive: Binding that triggers the confetti when set to true.
  ///   - colors: Colors for the confetti particles. If `nil`, uses theme-derived colors.
  ///   - particleCount: Number of particles to emit.
  ///   - duration: How long the celebration lasts.
  public init(
    isActive: Binding<Bool>,
    colors: [Color]? = nil,
    particleCount: Int = 50,
    duration: Double = 2.0,
  ) {
    _isActive = isActive
    customColors = colors
    self.particleCount = particleCount
    self.duration = duration
  }

  // MARK: Public

  public func body(content: Content) -> some View {
    content
      .overlay {
        if isActive {
          if reduceMotion {
            ConfettiReducedMotionView(
              color: effectiveColors.first ?? theme.colors.primary,
              onComplete: {
                isActive = false
              },
            )
            .allowsHitTesting(false)
          } else {
            ConfettiCanvas(
              colors: effectiveColors,
              particleCount: particleCount,
              duration: duration,
              onComplete: {
                isActive = false
              },
            )
            .allowsHitTesting(false)
          }
        }
      }
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  @Binding private var isActive: Bool

  private let customColors: [Color]?
  private let particleCount: Int
  private let duration: Double

  /// Theme-derived celebration colors.
  private var themeColors: [Color] {
    [
      theme.colors.primary,
      theme.colors.secondary,
      theme.colors.accent,
      theme.colors.success,
      theme.colors.warning,
      theme.colors.error,
      theme.colors.info,
    ]
  }

  /// The effective colors to use, preferring custom colors over theme-derived colors.
  private var effectiveColors: [Color] {
    customColors ?? themeColors
  }
}

// MARK: - ConfettiCanvas

/// Internal Canvas-based confetti renderer.
private struct ConfettiCanvas: View {

  // MARK: Internal

  let colors: [Color]
  let particleCount: Int
  let duration: Double
  let onComplete: () -> Void

  var body: some View {
    TimelineView(.animation) { timeline in
      Canvas { context, size in
        guard let startTime else { return }

        let elapsed = timeline.date.timeIntervalSince(startTime)

        // Check if animation is complete
        if elapsed >= duration {
          DispatchQueue.main.async {
            onComplete()
          }
          return
        }

        for particle in particles {
          let gravity: CGFloat = 400

          // Calculate position with physics
          let x = particle.startX + particle.velocityX * elapsed
          let y = particle.startY + particle.velocityY * elapsed + 0.5 * gravity * elapsed * elapsed

          // Calculate opacity (fade out in last 30%)
          var opacity = 1.0
          if elapsed > duration * 0.7 {
            let fadeProgress = (elapsed - duration * 0.7) / (duration * 0.3)
            opacity = max(0, 1.0 - fadeProgress)
          }

          // Calculate rotation
          let rotation = Angle.degrees(particle.rotation + particle.rotationSpeed * elapsed)

          // Skip if off-screen
          if y > size.height + 50 { continue }

          // Draw particle
          context.opacity = opacity
          context.translateBy(x: x, y: y)
          context.rotate(by: rotation)

          let rect = CGRect(
            x: -particle.size / 2,
            y: -particle.size / 2,
            width: particle.size,
            height: particle.size * particle.aspectRatio,
          )

          switch particle.shape {
          case .circle:
            context.fill(Circle().path(in: rect), with: .color(particle.color))
          case .rectangle:
            context.fill(Rectangle().path(in: rect), with: .color(particle.color))
          case .triangle:
            var path = Path()
            path.move(to: CGPoint(x: 0, y: -particle.size / 2))
            path.addLine(to: CGPoint(x: particle.size / 2, y: particle.size / 2))
            path.addLine(to: CGPoint(x: -particle.size / 2, y: particle.size / 2))
            path.closeSubpath()
            context.fill(path, with: .color(particle.color))
          }

          context.rotate(by: -rotation)
          context.translateBy(x: -x, y: -y)
        }
      }
    }
    .onAppear {
      startTime = Date()
      generateParticles()
    }
  }

  // MARK: Private

  @State private var startTime: Date?
  @State private var particles = [ConfettiParticle]()

  private func generateParticles() {
    particles = (0 ..< particleCount).map { _ in
      ConfettiParticle(
        startX: CGFloat.random(in: 50 ... 350),
        startY: CGFloat.random(in: -50 ... -10),
        velocityX: CGFloat.random(in: -150 ... 150),
        velocityY: CGFloat.random(in: 100 ... 400),
        size: CGFloat.random(in: 6 ... 12),
        aspectRatio: CGFloat.random(in: 1.0 ... 2.5),
        rotation: Double.random(in: 0 ... 360),
        rotationSpeed: Double.random(in: -360 ... 360),
        color: colors.randomElement() ?? .red,
        shape: ConfettiShape.allCases.randomElement() ?? .circle,
      )
    }
  }
}

// MARK: - ConfettiParticle

private struct ConfettiParticle {
  let startX: CGFloat
  let startY: CGFloat
  let velocityX: CGFloat
  let velocityY: CGFloat
  let size: CGFloat
  let aspectRatio: CGFloat
  let rotation: Double
  let rotationSpeed: Double
  let color: Color
  let shape: ConfettiShape
}

// MARK: - ConfettiShape

private enum ConfettiShape: CaseIterable {
  case circle
  case rectangle
  case triangle
}

// MARK: - ConfettiReducedMotionView

/// A simple celebration indicator for users with Reduce Motion enabled.
///
/// Shows a brief checkmark with a subtle scale animation instead of
/// the full confetti effect.
private struct ConfettiReducedMotionView: View {

  // MARK: Internal

  let color: Color
  let onComplete: () -> Void

  var body: some View {
    ZStack {
      if isShowing {
        Image(systemName: "checkmark.circle.fill")
          .font(.system(size: 64, weight: .medium))
          .foregroundStyle(color)
          .accessibilityLabel("Celebration complete")
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .onAppear {
      isShowing = true

      // Complete after a brief display
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
        isShowing = false
        onComplete()
      }
    }
  }

  // MARK: Private

  @State private var isShowing = false

}

// MARK: - View Extension

extension View {
  /// Adds a confetti celebration effect.
  ///
  /// When `isActive` becomes true, confetti bursts from the top
  /// of the view and falls down with physics-based animation.
  /// Automatically uses theme-derived colors and respects the
  /// Reduce Motion accessibility setting.
  ///
  /// ```swift
  /// @State private var celebrate = false
  ///
  /// SuccessView()
  ///   .ironConfetti(isActive: $celebrate)
  /// ```
  ///
  /// - Parameters:
  ///   - isActive: Binding that triggers confetti when true.
  ///   - colors: Confetti particle colors. If `nil`, uses theme-derived colors.
  ///   - particleCount: Number of particles.
  ///   - duration: Celebration duration.
  /// - Returns: A view with confetti capability.
  public func ironConfetti(
    isActive: Binding<Bool>,
    colors: [Color]? = nil,
    particleCount: Int = 50,
    duration: Double = 2.0,
  ) -> some View {
    modifier(
      IronConfettiModifier(
        isActive: isActive,
        colors: colors,
        particleCount: particleCount,
        duration: duration,
      )
    )
  }
}

// MARK: - IronConfettiView

/// A standalone confetti view that can be placed in a ZStack.
///
/// Use this when you need more control over positioning. Automatically
/// uses theme-derived colors and respects the Reduce Motion accessibility setting.
///
/// ```swift
/// ZStack {
///   ContentView()
///   if showConfetti {
///     IronConfettiView()
///   }
/// }
/// ```
public struct IronConfettiView: View {

  // MARK: Lifecycle

  /// Creates a standalone confetti view.
  ///
  /// - Parameters:
  ///   - colors: Confetti particle colors. If `nil`, uses theme-derived colors.
  ///   - particleCount: Number of particles to emit.
  public init(
    colors: [Color]? = nil,
    particleCount: Int = 50,
  ) {
    customColors = colors
    self.particleCount = particleCount
  }

  // MARK: Public

  public var body: some View {
    Group {
      if reduceMotion {
        // Show static checkmark for reduce motion
        Image(systemName: "checkmark.circle.fill")
          .font(.system(size: 64, weight: .medium))
          .foregroundStyle(effectiveColors.first ?? theme.colors.primary)
          .accessibilityLabel("Celebration complete")
      } else {
        TimelineView(.animation) { timeline in
          Canvas { context, _ in
            let elapsed = timeline.date.timeIntervalSince(startTime)

            for particle in particles {
              let gravity: CGFloat = 400

              // Calculate position
              let x = particle.startX + particle.velocityX * elapsed
              let y = particle.startY + particle.velocityY * elapsed + 0.5 * gravity * elapsed * elapsed

              // Calculate opacity
              let progress = elapsed / 2.0
              let opacity = max(0, 1 - progress)

              // Calculate rotation
              let rotation = Angle.degrees(particle.rotation + particle.rotationSpeed * elapsed)

              // Draw particle
              context.opacity = opacity
              context.translateBy(x: x, y: y)
              context.rotate(by: rotation)

              let rect = CGRect(
                x: -particle.size / 2,
                y: -particle.size / 2,
                width: particle.size,
                height: particle.size * particle.aspectRatio,
              )

              switch particle.shape {
              case 0:
                context.fill(Circle().path(in: rect), with: .color(particle.color))
              case 1:
                context.fill(Rectangle().path(in: rect), with: .color(particle.color))
              default:
                var path = Path()
                path.move(to: CGPoint(x: 0, y: -particle.size / 2))
                path.addLine(to: CGPoint(x: particle.size / 2, y: particle.size / 2))
                path.addLine(to: CGPoint(x: -particle.size / 2, y: particle.size / 2))
                path.closeSubpath()
                context.fill(path, with: .color(particle.color))
              }

              context.rotate(by: -rotation)
              context.translateBy(x: -x, y: -y)
            }
          }
        }
        .onAppear {
          startTime = Date()
          generateParticles()
        }
      }
    }
    .allowsHitTesting(false)
  }

  // MARK: Private

  private struct CanvasParticle {
    let startX: CGFloat
    let startY: CGFloat
    let velocityX: CGFloat
    let velocityY: CGFloat
    let size: CGFloat
    let aspectRatio: CGFloat
    let rotation: Double
    let rotationSpeed: Double
    let color: Color
    let shape: Int
  }

  @Environment(\.ironTheme) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  @State private var startTime = Date()
  @State private var particles = [CanvasParticle]()

  private let customColors: [Color]?
  private let particleCount: Int

  /// Theme-derived celebration colors.
  private var themeColors: [Color] {
    [
      theme.colors.primary,
      theme.colors.secondary,
      theme.colors.accent,
      theme.colors.success,
      theme.colors.warning,
      theme.colors.error,
      theme.colors.info,
    ]
  }

  /// The effective colors to use, preferring custom colors over theme-derived colors.
  private var effectiveColors: [Color] {
    customColors ?? themeColors
  }

  private func generateParticles() {
    particles = (0 ..< particleCount).map { _ in
      CanvasParticle(
        startX: CGFloat.random(in: 0 ... 400),
        startY: CGFloat.random(in: -50 ... -10),
        velocityX: CGFloat.random(in: -100 ... 100),
        velocityY: CGFloat.random(in: 100 ... 300),
        size: CGFloat.random(in: 6 ... 12),
        aspectRatio: CGFloat.random(in: 1.0 ... 2.5),
        rotation: Double.random(in: 0 ... 360),
        rotationSpeed: Double.random(in: -180 ... 180),
        color: effectiveColors.randomElement()!,
        shape: Int.random(in: 0 ... 2),
      )
    }
  }
}

// MARK: - Previews

#Preview("IronConfetti - Triggered") {
  @Previewable @State var showConfetti = false

  VStack(spacing: 32) {
    Text("Tap to celebrate!")
      .font(.headline)

    Button {
      showConfetti = true
    } label: {
      Text("🎉 Celebrate!")
        .font(.title2)
        .fontWeight(.semibold)
        .foregroundStyle(.white)
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .background(Color.blue)
        .clipShape(Capsule())
    }
  }
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .ironConfetti(isActive: $showConfetti)
}

#Preview("IronConfetti - Custom Colors") {
  @Previewable @State var showConfetti = false

  VStack(spacing: 32) {
    Button("Gold Celebration") {
      showConfetti = true
    }
    .buttonStyle(.borderedProminent)
    .tint(.orange)
  }
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .ironConfetti(
    isActive: $showConfetti,
    colors: [.yellow, .orange, Color(red: 1, green: 0.84, blue: 0)],
    particleCount: 80,
  )
}

#Preview("IronConfettiView - Standalone") {
  ZStack {
    Color.black.opacity(0.9)
      .ignoresSafeArea()

    VStack {
      Text("You did it!")
        .font(.largeTitle)
        .fontWeight(.bold)
        .foregroundStyle(.white)
    }

    IronConfettiView()
  }
}
