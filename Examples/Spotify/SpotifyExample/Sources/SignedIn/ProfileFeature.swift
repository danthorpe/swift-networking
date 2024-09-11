import ComposableArchitecture
import ComposableLoadable
import SpotifyClient

@Reducer
package struct ProfileFeature {
  @ObservableState
  package struct State: Loadable {
    package typealias Request = EmptyLoadRequest
    var me: User
  }
}
