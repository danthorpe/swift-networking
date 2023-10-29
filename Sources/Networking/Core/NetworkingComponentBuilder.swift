@resultBuilder
public enum NetworkingComponentBuilder {
  @inlinable
  public static func buildBlock<C: NetworkingComponent>(_ component: C) -> C {
    component
  }
  @inlinable
  public static func buildEither<C0: NetworkingComponent, C1: NetworkingComponent>(
    first component: C0
  ) -> _ConditionalComponent<C0, C1> {
    .first(component)
  }
  @inlinable
  public static func buildEither<C0: NetworkingComponent, C1: NetworkingComponent>(
    second component: C1
  ) -> _ConditionalComponent<C0, C1> {
    .second(component)
  }
  @inlinable
  public static func buildExpression<C: NetworkingComponent>(_ expression: C) -> C {
    expression
  }
  @inlinable
  public static func buildFinalResult<C: NetworkingComponent>(_ component: C) -> C {
    component
  }
  @inlinable
  public static func buildLimitedAvailability<C: NetworkingComponent>(_ component: C) -> _ErasedComponent {
    _ErasedComponent(component)
  }
  @inlinable
  public static func buildOptional<C: NetworkingComponent>(_ component: C?) -> C? {
    component
  }
}

// swiftlint:disable type_name

public enum _ConditionalComponent<First: NetworkingComponent, Second: NetworkingComponent>: NetworkingComponent {
  case first(First)
  case second(Second)
  public func send(_ request: HTTPRequestData) -> ResponseStream<HTTPResponseData> {
    switch self {
    case .first(let component):
      return component.send(request)
    case .second(let component):
      return component.send(request)
    }
  }
}

public struct _ErasedComponent: NetworkingComponent {
  @usableFromInline
  let other: any NetworkingComponent
  @usableFromInline
  init(_ other: some NetworkingComponent) {
    self.other = other
  }
  @inlinable
  public func send(_ request: HTTPRequestData) -> ResponseStream<HTTPResponseData> {
    other.send(request)
  }
}

// swiftlint:enable type_name
