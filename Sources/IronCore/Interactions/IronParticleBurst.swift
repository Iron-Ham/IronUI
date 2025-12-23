import SwiftUI

// MARK: - IronParticle

/// A burst of emoji or symbol particles.
///
/// Creates flying emoji or SF Symbol bursts like Honkish's
/// double-tap hearts and emoji reactions.
///
/// ## Double-Tap Hearts
///
/// ```swift
/// @State private var hearts: [IronParticle] = []
///
/// ContentView()
///   .ironParticleBurst(particles: $hearts)
///   .onTapGesture(count: 2) { location in
///     hearts.append(IronParticle(emoji: "❤️", position: location))
///   }
/// ```
///
/// ## Emoji Reactions
///
/// ```swift
/// Button("React") {
///   particles.append(
///     IronParticle(emoji: "🎉", position: buttonCenter, style: .burst)
///   )
/// }
/// ```
public struct IronParticle: Identifiable, Equatable {

  // MARK: Lifecycle

  /// Creates a particle with an emoji.
  ///
  /// - Parameters:
  ///   - emoji: The emoji character to display.
  ///   - position: Starting position.
  ///   - style: Animation style for the particle.
  public init(
    emoji: String,
    position: CGPoint,
    style: IronParticleStyle = .float,
  ) {
    id = UUID()
    content = .emoji(emoji)
    self.position = position
    self.style = style
  }

  /// Creates a particle with an SF Symbol.
  ///
  /// - Parameters:
  ///   - systemName: SF Symbol name.
  ///   - color: Symbol color.
  ///   - position: Starting position.
  ///   - style: Animation style.
  public init(
    systemName: String,
    color: Color = .red,
    position: CGPoint,
    style: IronParticleStyle = .float,
  ) {
    id = UUID()
    content = .symbol(systemName, color)
    self.position = position
    self.style = style
  }

  // MARK: Public

  /// The particle's unique identifier.
  public let id: UUID

  /// The content to display.
  public let content: IronParticleContent

  /// The starting position.
  public let position: CGPoint

  /// The animation style.
  public let style: IronParticleStyle

  public static func ==(lhs: IronParticle, rhs: IronParticle) -> Bool {
    lhs.id == rhs.id
  }
}

// MARK: - IronParticleContent

/// The content type for a particle.
public enum IronParticleContent: Equatable {
  /// An emoji character.
  case emoji(String)
  /// An SF Symbol with color.
  case symbol(String, Color)
}

// MARK: - IronParticleStyle

/// Animation styles for particles.
public enum IronParticleStyle: Sendable, Equatable {
  /// Floats upward and fades (like Instagram hearts).
  case float
  /// Bursts outward in multiple directions.
  case burst
  /// Flies in a direction with physics.
  case fly(angle: Double, speed: CGFloat)
}

// MARK: - IronParticleBurstModifier

/// A modifier that displays animated particle bursts.
public struct IronParticleBurstModifier: ViewModifier {

  // MARK: Lifecycle

  public init(particles: Binding<[IronParticle]>) {
    _particles = particles
  }

  // MARK: Public

  public func body(content: Content) -> some View {
    content
      .overlay {
        ZStack {
          ForEach(animatedParticles) { particle in
            ParticleContentView(content: particle.particle.content)
              .position(particle.currentPosition)
              .opacity(particle.opacity)
              .scaleEffect(particle.scale)
          }
        }
        .allowsHitTesting(false)
      }
      .onChange(of: particles) { oldValue, newValue in
        // Find new particles
        let newIds = Set(newValue.map(\.id))
        let oldIds = Set(oldValue.map(\.id))
        let addedIds = newIds.subtracting(oldIds)

        for particle in newValue where addedIds.contains(particle.id) {
          animateParticle(particle)
        }
      }
  }

  // MARK: Private

  private struct AnimatedParticle: Identifiable {
    let id: UUID
    let particle: IronParticle
    var currentPosition: CGPoint
    var opacity: Double
    var scale: CGFloat
  }

  @Binding private var particles: [IronParticle]
  @State private var animatedParticles = [AnimatedParticle]()

  private func animateParticle(_ particle: IronParticle) {
    switch particle.style {
    case .float:
      animateFloat(particle)
    case .burst:
      animateBurst(particle)
    case .fly(let angle, let speed):
      animateFly(particle, angle: angle, speed: speed)
    }
  }

  private func animateFloat(_ particle: IronParticle) {
    let animated = AnimatedParticle(
      id: particle.id,
      particle: particle,
      currentPosition: particle.position,
      opacity: 0,
      scale: 0.5,
    )
    animatedParticles.append(animated)

    // Appear
    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
      if let index = animatedParticles.firstIndex(where: { $0.id == particle.id }) {
        animatedParticles[index].opacity = 1
        animatedParticles[index].scale = 1.2
      }
    }

    // Float up and fade
    withAnimation(.easeOut(duration: 1.5)) {
      if let index = animatedParticles.firstIndex(where: { $0.id == particle.id }) {
        animatedParticles[index].currentPosition.y -= 150
        animatedParticles[index].currentPosition.x += CGFloat.random(in: -30 ... 30)
        animatedParticles[index].scale = 0.8
      }
    }

    withAnimation(.easeOut(duration: 0.5).delay(1.0)) {
      if let index = animatedParticles.firstIndex(where: { $0.id == particle.id }) {
        animatedParticles[index].opacity = 0
      }
    }

    // Cleanup
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
      animatedParticles.removeAll { $0.id == particle.id }
      particles.removeAll { $0.id == particle.id }
    }
  }

  private func animateBurst(_ particle: IronParticle) {
    // Create multiple particles in a burst pattern
    let burstCount = 6
    for i in 0 ..< burstCount {
      let angle = (Double(i) / Double(burstCount)) * 2 * .pi
      let burstId = UUID()

      let animated = AnimatedParticle(
        id: burstId,
        particle: particle,
        currentPosition: particle.position,
        opacity: 1,
        scale: 0.3,
      )
      animatedParticles.append(animated)

      // Burst outward
      withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
        if let index = animatedParticles.firstIndex(where: { $0.id == burstId }) {
          let distance: CGFloat = 80
          animatedParticles[index].currentPosition.x += cos(angle) * distance
          animatedParticles[index].currentPosition.y += sin(angle) * distance
          animatedParticles[index].scale = 1.0
        }
      }

      // Fade out
      withAnimation(.easeOut(duration: 0.3).delay(0.3)) {
        if let index = animatedParticles.firstIndex(where: { $0.id == burstId }) {
          animatedParticles[index].opacity = 0
          animatedParticles[index].scale = 0.5
        }
      }

      // Cleanup
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
        animatedParticles.removeAll { $0.id == burstId }
      }
    }

    // Remove source particle
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
      particles.removeAll { $0.id == particle.id }
    }
  }

  private func animateFly(_ particle: IronParticle, angle: Double, speed: CGFloat) {
    let animated = AnimatedParticle(
      id: particle.id,
      particle: particle,
      currentPosition: particle.position,
      opacity: 1,
      scale: 1.0,
    )
    animatedParticles.append(animated)

    // Fly in direction
    withAnimation(.easeOut(duration: 1.0)) {
      if let index = animatedParticles.firstIndex(where: { $0.id == particle.id }) {
        animatedParticles[index].currentPosition.x += cos(angle) * speed
        animatedParticles[index].currentPosition.y += sin(angle) * speed
      }
    }

    // Fade at end
    withAnimation(.easeOut(duration: 0.3).delay(0.7)) {
      if let index = animatedParticles.firstIndex(where: { $0.id == particle.id }) {
        animatedParticles[index].opacity = 0
      }
    }

    // Cleanup
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      animatedParticles.removeAll { $0.id == particle.id }
      particles.removeAll { $0.id == particle.id }
    }
  }
}

// MARK: - ParticleContentView

/// Internal view that renders particle content.
private struct ParticleContentView: View {
  let content: IronParticleContent

  var body: some View {
    switch content {
    case .emoji(let emoji):
      Text(emoji)
        .font(.system(size: 32))

    case .symbol(let name, let color):
      Image(systemName: name)
        .font(.system(size: 28))
        .foregroundStyle(color)
    }
  }
}

// MARK: - View Extension

extension View {
  /// Adds a particle burst overlay.
  ///
  /// Particles animate based on their style and are automatically
  /// removed after animating.
  ///
  /// ```swift
  /// @State private var particles: [IronParticle] = []
  ///
  /// ContentView()
  ///   .ironParticleBurst(particles: $particles)
  ///   .onTapGesture(count: 2) { location in
  ///     particles.append(
  ///       IronParticle(emoji: "❤️", position: location)
  ///     )
  ///   }
  /// ```
  ///
  /// - Parameter particles: Binding to the array of particles to display.
  /// - Returns: A view with particle burst capability.
  public func ironParticleBurst(particles: Binding<[IronParticle]>) -> some View {
    modifier(IronParticleBurstModifier(particles: particles))
  }
}

// MARK: - IronHeartBurstModifier

/// A convenience modifier specifically for double-tap heart reactions.
///
/// ```swift
/// ImageView()
///   .ironHeartBurst()
/// ```
public struct IronHeartBurstModifier: ViewModifier {

  // MARK: Lifecycle

  public init(color: Color = .red) {
    self.color = color
  }

  // MARK: Public

  public func body(content: Content) -> some View {
    content
      .ironParticleBurst(particles: $particles)
      .simultaneousGesture(
        SpatialTapGesture(count: 2)
          .onEnded { event in
            particles.append(
              IronParticle(
                systemName: "heart.fill",
                color: color,
                position: event.location,
                style: .float,
              )
            )
          }
      )
  }

  // MARK: Private

  @State private var particles = [IronParticle]()

  private let color: Color
}

extension View {
  /// Adds double-tap heart reaction capability.
  ///
  /// Double-tapping anywhere on the view creates a floating
  /// heart animation at the tap location.
  ///
  /// - Parameter color: Heart color. Defaults to red.
  /// - Returns: A view with heart reaction capability.
  public func ironHeartBurst(color: Color = .red) -> some View {
    modifier(IronHeartBurstModifier(color: color))
  }
}

// MARK: - Previews

#Preview("IronParticleBurst - Hearts") {
  @Previewable @State var particles = [IronParticle]()

  VStack {
    Text("Double-tap anywhere!")
      .font(.headline)
      .padding(.bottom, 32)

    Image(systemName: "photo.fill")
      .font(.system(size: 100))
      .foregroundStyle(.secondary)
  }
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .background(Color.gray.opacity(0.1))
  .ironParticleBurst(particles: $particles)
  .onTapGesture(count: 2) { location in
    particles.append(
      IronParticle(emoji: "❤️", position: location, style: .float)
    )
  }
}

#Preview("IronHeartBurst - Simple") {
  VStack {
    Text("Double-tap the image!")
      .font(.headline)
      .padding(.bottom, 32)

    RoundedRectangle(cornerRadius: 16)
      .fill(
        LinearGradient(
          colors: [.purple, .pink],
          startPoint: .topLeading,
          endPoint: .bottomTrailing,
        )
      )
      .frame(width: 300, height: 300)
      .overlay {
        Image(systemName: "heart.fill")
          .font(.system(size: 50))
          .foregroundStyle(.white.opacity(0.3))
      }
      .ironHeartBurst()
  }
}

#Preview("IronParticleBurst - Burst Style") {
  @Previewable @State var particles = [IronParticle]()

  VStack(spacing: 24) {
    Text("Tap to burst!")
      .font(.headline)

    Button {
      particles.append(
        IronParticle(
          emoji: "🎉",
          position: CGPoint(x: 200, y: 400),
          style: .burst,
        )
      )
    } label: {
      Text("Celebrate")
        .font(.title2)
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .background(Color.orange)
        .foregroundStyle(.white)
        .clipShape(Capsule())
    }
  }
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .ironParticleBurst(particles: $particles)
}

#Preview("IronParticleBurst - Emoji Battle") {
  @Previewable @State var particles = [IronParticle]()

  let emojis = ["😀", "🎉", "❤️", "⭐️", "🔥", "💯"]

  VStack {
    Text("Tap buttons for emoji battle!")
      .font(.headline)
      .padding(.bottom)

    HStack(spacing: 16) {
      ForEach(emojis, id: \.self) { emoji in
        Button(emoji) {
          particles.append(
            IronParticle(
              emoji: emoji,
              position: CGPoint(
                x: CGFloat.random(in: 50 ... 350),
                y: 300,
              ),
              style: .fly(
                angle: Double.random(in: -.pi / 4 ... .pi / 4) - .pi / 2,
                speed: CGFloat.random(in: 150 ... 250),
              ),
            )
          )
        }
        .font(.title)
      }
    }
  }
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .ironParticleBurst(particles: $particles)
}
