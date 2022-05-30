import Foundation

public struct Response<Body> {
    public let http: HTTPResponse
    public let body: Body

    public var status: HTTPStatus {
        http.status
    }

    public init(http: HTTPResponse, body: Body) {
        self.http = http
        self.body = body
    }
}
