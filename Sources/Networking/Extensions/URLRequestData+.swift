import Foundation
import URLRouting

extension URLRequestData: CustomStringConvertible {

    public var description: String {
        "\(number) \(id) \(path.description)"
    }
}
