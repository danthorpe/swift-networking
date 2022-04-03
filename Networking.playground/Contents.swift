import HTTP
import Foundation

let loader = Loader {
    ResetGuard()
    TransportLoader(URLSession.shared)
        .throttle()
        .removeDuplicates()
        .cached(in: .memory)
}
