import ComposableArchitecture
import ComposableLoadable

@Reducer
struct ProfileFeature {
  @ObservableState
  struct State: Loadable {
    typealias Request = EmptyLoadRequest
    var me: User
  }
}
