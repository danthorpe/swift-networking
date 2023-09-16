import Networking

extension BytesReceived {
    public init(response: HTTPResponseData) {
        self.init(data: response.data)
    }
}
