import SwiftUI

extension EnvironmentValues {
  /// A shared namespace for matched geometry effects.
  ///
  /// Use this to share a namespace across a view hierarchy without
  /// passing it explicitly through initializers.
  ///
  /// ```swift
  /// @Namespace private var namespace
  ///
  /// SomeView()
  ///   .environment(\.ironNamespace, namespace)
  /// ```
  @Entry public var ironNamespace: Namespace.ID? = nil
}

// MARK: - View Extension

extension View {
  /// Applies a matched geometry effect using the shared Iron namespace.
  ///
  /// This is a convenience wrapper around `matchedGeometryEffect` that
  /// uses the environment's `ironNamespace` if available.
  ///
  /// ```swift
  /// @Namespace private var namespace
  ///
  /// VStack {
  ///   if showDetail {
  ///     DetailView()
  ///       .ironMatchedGeometry(id: "card")
  ///   } else {
  ///     CardView()
  ///       .ironMatchedGeometry(id: "card")
  ///   }
  /// }
  /// .environment(\.ironNamespace, namespace)
  /// ```
  ///
  /// - Parameters:
  ///   - id: A unique identifier for this geometry group.
  ///   - properties: Which properties to match. Defaults to `.frame`.
  ///   - anchor: The anchor point for the geometry. Defaults to `.center`.
  ///   - isSource: Whether this view is the source of the geometry.
  /// - Returns: A view with matched geometry effect applied.
  public func ironMatchedGeometry(
    id: some Hashable,
    properties: MatchedGeometryProperties = .frame,
    anchor: UnitPoint = .center,
    isSource: Bool = true,
  ) -> some View {
    modifier(
      IronMatchedGeometryModifier(
        id: id,
        properties: properties,
        anchor: anchor,
        isSource: isSource,
      )
    )
  }
}

// MARK: - IronMatchedGeometryModifier

/// Internal modifier that applies matched geometry using the environment namespace.
private struct IronMatchedGeometryModifier<ID: Hashable>: ViewModifier {

  // MARK: Internal

  let id: ID
  let properties: MatchedGeometryProperties
  let anchor: UnitPoint
  let isSource: Bool

  func body(content: Content) -> some View {
    if let namespace {
      content
        .matchedGeometryEffect(
          id: id,
          in: namespace,
          properties: properties,
          anchor: anchor,
          isSource: isSource,
        )
    } else {
      content
    }
  }

  // MARK: Private

  @Environment(\.ironNamespace) private var namespace

}

// MARK: - IronHeroTransition

/// A container that enables hero transitions between child views.
///
/// `IronHeroTransition` provides a namespace for matched geometry effects,
/// making it easy to create smooth transitions where elements appear to
/// fly from one position to another.
///
/// ## Basic Usage
///
/// ```swift
/// @State private var showDetail = false
/// @State private var selectedItem: Item?
///
/// IronHeroTransition {
///   if let item = selectedItem {
///     DetailView(item: item)
///       .ironMatchedGeometry(id: item.id)
///       .transition(.opacity)
///   } else {
///     LazyVGrid(columns: columns) {
///       ForEach(items) { item in
///         CardView(item: item)
///           .ironMatchedGeometry(id: item.id)
///           .onTapGesture {
///             withAnimation(.smooth) {
///               selectedItem = item
///             }
///           }
///       }
///     }
///   }
/// }
/// ```
public struct IronHeroTransition<Content: View>: View {

  // MARK: Lifecycle

  /// Creates a hero transition container.
  ///
  /// - Parameter content: The content that may contain matched geometry elements.
  public init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  // MARK: Public

  public var body: some View {
    content
      .environment(\.ironNamespace, namespace)
  }

  // MARK: Private

  @Namespace private var namespace

  private let content: Content
}

// MARK: - Previews

#Preview("IronHeroTransition") {
  @Previewable @State var selectedColor: Color?

  let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple]

  IronHeroTransition {
    ZStack {
      // Grid of colors
      if selectedColor == nil {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 16) {
          ForEach(colors, id: \.self) { color in
            RoundedRectangle(cornerRadius: 12)
              .fill(color)
              .frame(height: 80)
              .ironMatchedGeometry(id: color)
              .onTapGesture {
                withAnimation(.smooth(duration: 0.4)) {
                  selectedColor = color
                }
              }
          }
        }
        .padding()
        .transition(.opacity)
      }

      // Selected color detail
      if let color = selectedColor {
        VStack {
          RoundedRectangle(cornerRadius: 24)
            .fill(color)
            .frame(height: 300)
            .ironMatchedGeometry(id: color)

          Text("Selected Color")
            .font(.title2)
            .padding(.top)

          Button("Close") {
            withAnimation(.smooth(duration: 0.4)) {
              selectedColor = nil
            }
          }
          .buttonStyle(.borderedProminent)
          .padding(.top)

          Spacer()
        }
        .padding()
        .transition(.opacity)
      }
    }
  }
}
