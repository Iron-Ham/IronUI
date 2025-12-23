import SwiftUI

// MARK: - IronShimmerModifier

/// A shimmer effect that sweeps across a view.
///
/// Creates a gentle shimmer animation to indicate loading,
/// hidden content, or background updates—like Family's stealth mode.
///
/// ## Basic Usage
///
/// ```swift
/// Text("$1,234.56")
///   .ironShimmer()
///
/// // Conditional shimmer
/// BalanceView()
///   .ironShimmer(active: isLoading)
/// ```
///
/// ## Stealth Mode Style
///
/// ```swift
/// // Subtle shimmer for hidden values
/// Text("••••••")
///   .ironShimmer(style: .stealth)
/// ```
public struct IronShimmerModifier: ViewModifier {

  // MARK: Lifecycle

  /// Creates a shimmer modifier.
  ///
  /// - Parameters:
  ///   - active: Whether the shimmer is animating.
  ///   - style: The shimmer visual style.
  ///   - duration: Duration of one shimmer cycle.
  public init(
    active: Bool = true,
    style: IronShimmerStyle = .standard,
    duration: Double = 1.5,
  ) {
    self.active = active
    self.style = style
    self.duration = duration
  }

  // MARK: Public

  public func body(content: Content) -> some View {
    content
      .overlay {
        if active {
          GeometryReader { geometry in
            shimmerGradient
              .frame(width: geometry.size.width * 2)
              .offset(x: animating ? geometry.size.width : -geometry.size.width)
          }
          .clipped()
          .allowsHitTesting(false)
        }
      }
      .onAppear {
        guard active else { return }
        startAnimation()
      }
      .onChange(of: active) { _, newValue in
        if newValue {
          startAnimation()
        }
      }
  }

  // MARK: Private

  @State private var animating = false

  private let active: Bool
  private let style: IronShimmerStyle
  private let duration: Double

  private var shimmerGradient: some View {
    LinearGradient(
      colors: style.gradientColors,
      startPoint: .leading,
      endPoint: .trailing,
    )
  }

  private func startAnimation() {
    animating = false
    withAnimation(
      .linear(duration: duration)
        .repeatForever(autoreverses: false)
    ) {
      animating = true
    }
  }
}

// MARK: - IronShimmerStyle

/// Visual styles for the shimmer effect.
public enum IronShimmerStyle: Sendable {
  /// Standard shimmer with subtle white highlight.
  case standard
  /// Very subtle shimmer for stealth/hidden content.
  case stealth
  /// More prominent shimmer for loading states.
  case loading
  /// Custom gradient colors.
  case custom([Color])

  // MARK: Internal

  var gradientColors: [Color] {
    switch self {
    case .standard:
      [
        Color.white.opacity(0),
        Color.white.opacity(0.3),
        Color.white.opacity(0),
      ]

    case .stealth:
      [
        Color.white.opacity(0),
        Color.white.opacity(0.1),
        Color.white.opacity(0),
      ]

    case .loading:
      [
        Color.white.opacity(0),
        Color.white.opacity(0.5),
        Color.white.opacity(0),
      ]

    case .custom(let colors):
      colors
    }
  }
}

// MARK: - View Extension

extension View {
  /// Adds a shimmer effect that sweeps across the view.
  ///
  /// Use shimmer to indicate loading states, hidden content,
  /// or subtle background activity.
  ///
  /// ```swift
  /// // Loading shimmer
  /// PlaceholderCard()
  ///   .ironShimmer(active: isLoading)
  ///
  /// // Stealth mode
  /// Text("$••••")
  ///   .ironShimmer(style: .stealth)
  /// ```
  ///
  /// - Parameters:
  ///   - active: Whether shimmer is animating.
  ///   - style: The shimmer visual style.
  ///   - duration: Duration of one cycle.
  /// - Returns: A view with shimmer effect.
  public func ironShimmer(
    active: Bool = true,
    style: IronShimmerStyle = .standard,
    duration: Double = 1.5,
  ) -> some View {
    modifier(
      IronShimmerModifier(
        active: active,
        style: style,
        duration: duration,
      )
    )
  }
}

// MARK: - IronShimmerView

/// A standalone shimmer placeholder view.
///
/// Use this for skeleton loading states where you want
/// to show placeholder content with shimmer.
///
/// ```swift
/// if isLoading {
///   IronShimmerView()
///     .frame(height: 100)
///     .clipShape(RoundedRectangle(cornerRadius: 12))
/// } else {
///   ContentView()
/// }
/// ```
public struct IronShimmerView: View {

  // MARK: Lifecycle

  /// Creates a shimmer placeholder view.
  ///
  /// - Parameters:
  ///   - baseColor: The background color.
  ///   - highlightColor: The shimmer highlight color.
  public init(
    baseColor: Color = Color.gray.opacity(0.2),
    highlightColor: Color = Color.white.opacity(0.4),
  ) {
    self.baseColor = baseColor
    self.highlightColor = highlightColor
  }

  // MARK: Public

  public var body: some View {
    GeometryReader { geometry in
      baseColor
        .overlay {
          LinearGradient(
            colors: [
              highlightColor.opacity(0),
              highlightColor,
              highlightColor.opacity(0),
            ],
            startPoint: .leading,
            endPoint: .trailing,
          )
          .frame(width: geometry.size.width * 0.6)
          .offset(x: animating ? geometry.size.width : -geometry.size.width)
        }
        .clipped()
    }
    .onAppear {
      withAnimation(
        .linear(duration: 1.2)
          .repeatForever(autoreverses: false)
      ) {
        animating = true
      }
    }
  }

  // MARK: Private

  @State private var animating = false

  private let baseColor: Color
  private let highlightColor: Color
}

// MARK: - Previews

#Preview("IronShimmer - Styles") {
  VStack(spacing: 24) {
    Text("Shimmer Styles")
      .font(.headline)

    Group {
      Text("Standard Shimmer")
        .font(.title2)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.blue.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .ironShimmer(style: .standard)

      Text("Stealth Mode")
        .font(.title2)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .ironShimmer(style: .stealth)

      Text("Loading...")
        .font(.title2)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.purple.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .ironShimmer(style: .loading)
    }
  }
  .padding()
}

#Preview("IronShimmer - Stealth Balance") {
  VStack(spacing: 16) {
    Text("Stealth Mode Active")
      .font(.caption)
      .foregroundStyle(.secondary)

    HStack {
      Text("Balance:")
      Spacer()
      Text("$••••••")
        .fontWeight(.semibold)
        .ironShimmer(style: .stealth, duration: 2.0)
    }
    .font(.title3)
    .padding()
    .background(Color.secondary.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }
  .padding()
}

#Preview("IronShimmerView - Skeleton") {
  VStack(spacing: 16) {
    Text("Loading Content...")
      .font(.headline)

    // Skeleton card
    VStack(alignment: .leading, spacing: 12) {
      IronShimmerView()
        .frame(height: 20)
        .frame(width: 150)
        .clipShape(Capsule())

      IronShimmerView()
        .frame(height: 14)
        .clipShape(Capsule())

      IronShimmerView()
        .frame(height: 14)
        .frame(width: 200)
        .clipShape(Capsule())

      IronShimmerView()
        .frame(height: 100)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    .padding()
    .background(Color.secondary.opacity(0.05))
    .clipShape(RoundedRectangle(cornerRadius: 16))
  }
  .padding()
}

#Preview("IronShimmer - Conditional") {
  @Previewable @State var isLoading = true

  VStack(spacing: 24) {
    Toggle("Loading", isOn: $isLoading)

    Text("Content that shimmers while loading")
      .font(.title3)
      .padding()
      .frame(maxWidth: .infinity)
      .background(Color.green.opacity(0.2))
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .ironShimmer(active: isLoading)
  }
  .padding()
}
