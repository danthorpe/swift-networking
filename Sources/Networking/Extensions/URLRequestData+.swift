import Foundation
import URLRouting

extension URLRequestData: CustomStringConvertible {

    public var description: String {
        var queryDesc = ""
        if !query.isEmpty {
            let parameters = query.fields.map { key, value in
                value.compactMap { String("\(key)=\($0!)") }.joined(separator: "&")
            }
            queryDesc = "?\(parameters.joined(separator: "&"))"
        }
        var prefix = ""
        if let number = RequestMetadata.number, let id = RequestMetadata.id {
            prefix = "\(number):\(id) "
        }
        return "\(prefix)/\(path.joined(separator: "/"))\(queryDesc)"
    }
}
