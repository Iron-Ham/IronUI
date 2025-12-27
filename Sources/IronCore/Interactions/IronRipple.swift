import SwiftUI

// MARK: - IronRippleModifier

/// A ripple effect that emanates from the touch point.
///
/// Creates a gentle ripple animation when the user taps, similar to
/// tapping a QR code in Family or Material Design's touch feedback.
///
/// ## Usage
///
/// ```swift
/// Button("Tap Me") { }
///   .ironRipple()
///
/// // Custom color
/// Image(systemName: "qrcode")
///   .ironRipple(color: .blue.opacity(0.3))
/// ```
public struct IronRippleModifier: ViewModifier {

  // MARK: Lifecycle

  /// Creates a ripple modifier.
  ///
  /// - Parameters:
  ///   - color: The ripple color. If `nil`, uses a theme-derived color.
  ///   - duration: How long the ripple animation lasts.
  public init(
    color: Color? = nil,
    duration: Double = 0.5,
  ) {
    customColor = color
    self.duration = duration
  }

  // MARK: Public

  public func body(content: Content) -> some View {
    content
      .overlay {
        GeometryReader { geometry in
          ZStack {
            // Reduce motion: show a brief flash overlay instead of expanding ripple
            if reduceMotion {
              if flashPosition != nil {
                Rectangle()
                  .fill(effectiveColor)
                  .position(
                    x: geometry.size.width / 2,
                    y: geometry.size.height / 2,
                  )
                  .frame(
                    width: geometry.size.width,
                    height: geometry.size.height,
                  )
                  .opacity(flashOpacity)
              }
            } else {
              ForEach(ripples) { ripple in
                Circle()
                  .fill(effectiveColor)
                  .frame(width: ripple.size, height: ripple.size)
                  .position(ripple.position)
                  .opacity(ripple.opacity)
              }
            }
          }
          .allowsHitTesting(false)
          .contentShape(Rectangle())
          .simultaneousGesture(
            DragGesture(minimumDistance: 0)
              .onChanged { value in
                if !isDragging {
                  isDragging = true
                  if reduceMotion {
                    triggerFlash(at: value.location)
                  } else {
                    triggerRipple(at: value.location, in: geometry.size)
                  }
                }
              }
              .onEnded { _ in
                isDragging = false
              }
          )
        }
        .clipped()
      }
      .contentShape(Rectangle())
  }

  // MARK: Private

  private struct Ripple: Identifiable {
    let id = UUID()
    let position: CGPoint
    var size: CGFloat
    var opacity: Double
  }

  @Environment(\.ironTheme) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  @State private var ripples = [Ripple]()
  @State private var isDragging = false
  @State private var flashPosition: CGPoint?
  @State private var flashOpacity: Double = 0

  private let customColor: Color?
  private let duration: Double

  /// The effective color to use, preferring custom color over theme-derived color.
  private var effectiveColor: Color {
    customColor ?? theme.colors.primary.opacity(0.12)
  }

  private func triggerRipple(at position: CGPoint, in viewSize: CGSize) {
    let ripple = Ripple(position: position, size: 0, opacity: 1)
    ripples.append(ripple)

    // Calculate ripple size based on view size (max dimension * 1.2)
    let targetSize = max(viewSize.width, viewSize.height) * 1.2

    // Animate the ripple expanding and fading
    withAnimation(.easeOut(duration: duration)) {
      if let index = ripples.firstIndex(where: { $0.id == ripple.id }) {
        ripples[index].size = targetSize
        ripples[index].opacity = 0
      }
    }

    // Remove ripple after animation
    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
      ripples.removeAll { $0.id == ripple.id }
    }
  }

  private func triggerFlash(at position: CGPoint) {
    flashPosition = position
    flashOpacity = 1

    // Brief flash without animation for reduce motion
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
      flashOpacity = 0
    }

    // Cleanup
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      flashPosition = nil
    }
  }
}

// MARK: - View Extension

extension View {
  /// Adds a ripple effect that emanates from touch points.
  ///
  /// The ripple provides subtle tactile feedback, making taps feel
  /// more responsive and satisfying. Automatically uses theme-derived
  /// colors and respects the Reduce Motion accessibility setting.
  ///
  /// ```swift
  /// Button("Action") { }
  ///   .ironRipple()
  ///
  /// // With custom styling
  /// CardView()
  ///   .ironRipple(color: .blue.opacity(0.2), duration: 0.6)
  /// ```
  ///
  /// - Parameters:
  ///   - color: The ripple color. If `nil`, uses a theme-derived color.
  ///   - duration: Animation duration in seconds.
  /// - Returns: A view with ripple effect applied.
  public func ironRipple(
    color: Color? = nil,
    duration: Double = 0.5,
  ) -> some View {
    modifier(IronRippleModifier(color: color, duration: duration))
  }
}

// MARK: - IronSequinRippleModifier

/// A sequin-like ripple effect with multiple dots.
///
/// Creates a more elaborate ripple with scattered dots, similar to
/// the sequin transformation effect in Family. Automatically uses
/// theme-derived colors and respects the Reduce Motion accessibility setting.
///
/// ```swift
/// QRCodeView()
///   .ironSequinRipple()
/// ```
public struct IronSequinRippleModifier: ViewModifier {

  // MARK: Lifecycle

  /// Creates a sequin ripple modifier.
  ///
  /// - Parameters:
  ///   - color: The dot color. If `nil`, uses a theme-derived color.
  ///   - dotCount: Number of dots in the burst.
  public init(
    color: Color? = nil,
    dotCount: Int = 12,
  ) {
    customColor = color
    self.dotCount = dotCount
  }

  // MARK: Public

  public func body(content: Content) -> some View {
    content
      .overlay {
        GeometryReader { geometry in
          ZStack {
            // Reduce motion: show a brief flash overlay instead of scattered dots
            if reduceMotion {
              if flashPosition != nil {
                Rectangle()
                  .fill(effectiveColor)
                  .position(
                    x: geometry.size.width / 2,
                    y: geometry.size.height / 2,
                  )
                  .frame(
                    width: geometry.size.width,
                    height: geometry.size.height,
                  )
                  .opacity(flashOpacity)
              }
            } else {
              ForEach(dots) { dot in
                Circle()
                  .fill(effectiveColor)
                  .frame(width: dot.size, height: dot.size)
                  .position(dot.position)
                  .opacity(dot.opacity)
              }
            }
          }
          .allowsHitTesting(false)
        }
        .clipped()
      }
      .contentShape(Rectangle())
      .simultaneousGesture(
        DragGesture(minimumDistance: 0)
          .onChanged { value in
            if !isDragging {
              isDragging = true
              if reduceMotion {
                triggerFlash(at: value.location)
              } else {
                triggerSequins(at: value.location)
              }
            }
          }
          .onEnded { _ in
            isDragging = false
          }
      )
  }

  // MARK: Private

  private struct Dot: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var opacity: Double
    let angle: Double
    let distance: CGFloat
  }

  @Environment(\.ironTheme) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  @State private var dots = [Dot]()
  @State private var isDragging = false
  @State private var flashPosition: CGPoint?
  @State private var flashOpacity: Double = 0

  private let customColor: Color?
  private let dotCount: Int

  /// The effective color to use, preferring custom color over theme-derived color.
  private var effectiveColor: Color {
    customColor ?? theme.colors.primary.opacity(0.15)
  }

  private func triggerSequins(at center: CGPoint) {
    // Create dots radiating outward
    for i in 0 ..< dotCount {
      let angle = (Double(i) / Double(dotCount)) * 2 * .pi
      let randomOffset = Double.random(in: -0.3 ... 0.3)

      let dot = Dot(
        position: center,
        size: CGFloat.random(in: 4 ... 8),
        opacity: 1,
        angle: angle + randomOffset,
        distance: CGFloat.random(in: 40 ... 80),
      )
      dots.append(dot)

      // Animate each dot outward
      withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
        if let index = dots.firstIndex(where: { $0.id == dot.id }) {
          let newX = center.x + cos(dot.angle) * dot.distance
          let newY = center.y + sin(dot.angle) * dot.distance
          dots[index].position = CGPoint(x: newX, y: newY)
        }
      }

      // Fade out
      withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
        if let index = dots.firstIndex(where: { $0.id == dot.id }) {
          dots[index].opacity = 0
        }
      }

      // Cleanup
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
        dots.removeAll { $0.id == dot.id }
      }
    }
  }

  private func triggerFlash(at position: CGPoint) {
    flashPosition = position
    flashOpacity = 1

    // Brief flash without animation for reduce motion
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
      flashOpacity = 0
    }

    // Cleanup
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      flashPosition = nil
    }
  }
}

extension View {
  /// Adds a sequin-like ripple effect with scattered dots.
  ///
  /// Creates a more elaborate feedback effect with multiple dots
  /// radiating outward from the touch point. Automatically uses
  /// theme-derived colors and respects the Reduce Motion accessibility setting.
  ///
  /// - Parameters:
  ///   - color: The dot color. If `nil`, uses a theme-derived color.
  ///   - dotCount: Number of dots in the burst.
  /// - Returns: A view with sequin ripple applied.
  public func ironSequinRipple(
    color: Color? = nil,
    dotCount: Int = 12,
  ) -> some View {
    modifier(IronSequinRippleModifier(color: color, dotCount: dotCount))
  }
}

// MARK: - Previews

#Preview("IronRipple - Basic") {
  VStack(spacing: 24) {
    Text("Tap anywhere on the cards")
      .font(.headline)

    RoundedRectangle(cornerRadius: 16)
      .fill(Color.blue.opacity(0.1))
      .frame(height: 100)
      .overlay {
        Text("Basic Ripple")
      }
      .ironRipple()

    RoundedRectangle(cornerRadius: 16)
      .fill(Color.green.opacity(0.1))
      .frame(height: 100)
      .overlay {
        Text("Custom Color")
      }
      .ironRipple(color: .green.opacity(0.3))

    RoundedRectangle(cornerRadius: 16)
      .fill(Color.purple.opacity(0.1))
      .frame(height: 100)
      .overlay {
        Text("Slow Ripple")
      }
      .ironRipple(duration: 1.0)
  }
  .padding()
}

#Preview("IronSequinRipple") {
  VStack(spacing: 24) {
    Text("Tap for sequin effect")
      .font(.headline)

    RoundedRectangle(cornerRadius: 16)
      .fill(Color.orange.opacity(0.1))
      .frame(height: 150)
      .overlay {
        Image(systemName: "qrcode")
          .font(.system(size: 60))
          .foregroundStyle(.orange)
      }
      .ironSequinRipple(color: .orange.opacity(0.4))

    RoundedRectangle(cornerRadius: 16)
      .fill(Color.pink.opacity(0.1))
      .frame(height: 150)
      .overlay {
        Text("More Dots")
      }
      .ironSequinRipple(dotCount: 20)
  }
  .padding()
}
