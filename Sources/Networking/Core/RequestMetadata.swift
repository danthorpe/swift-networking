import Foundation
import Tagged
import URLRouting

struct RequestMetadata {
    @TaskLocal
    static var number: Int!

    @TaskLocal
    static var id: Tagged<URLRequestData, String>!
}
