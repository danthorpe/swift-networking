import Foundation
import URLRouting

extension URLRequestData: CustomStringConvertible {

    public var description: String {
        var queryDesc = ""
        if !query.isEmpty {
            queryDesc = "?\(query.fields.description)"
        }
        return "\(number):\(id) /\(path.joined(separator: "/"))\(queryDesc)"
    }
}
