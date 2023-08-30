import Foundation

extension URLSession: NetworkingComponent {
    public func send(_ request: HTTPRequestData) -> ResponseStream<HTTPResponseData> {
        ResponseStream<HTTPResponseData> { continuation in
            Task {
                guard let urlRequest = URLRequest(http: request) else {
                    continuation.finish(throwing: StackError.createURLRequestFailed(request))
                    return
                }
                do {
                    await send(urlRequest)
                        .map { partial in
                            try partial.mapValue { data, response in
                                try HTTPResponseData(request: request, data: data, urlResponse: response)
                            }
                        }
                        .eraseToThrowingStream()
                        .redirect(into: continuation)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    @Sendable func send(_ request: URLRequest) -> ResponseStream<(Data, URLResponse)> {
        ResponseStream<(Data, URLResponse)> { continuation in
            Task {
                do {
                    // Define a buffer to download bytes into
                    let bufferSize = 16_384 // 16kB
                    var data = Data()

                    // Get an AsyncBytes for the request
                    let (bytes, response) = try await self.bytes(for: request)

                    // Co-operative cancellation
                    try Task.checkCancellation()

                    // Track the progress of bytes received
                    var progress = BytesReceived(expected: response.expectedContentLength)
                    var bufferCount = 0

                    // Configure the buffer
                    data.reserveCapacity(min(bufferSize, Int(progress.expected)))

                    // Iterate through the bytes
                    for try await byte in bytes {

                        // Fill up the in-memory buffer with bytes
                        data.append(byte)

                        // Count how many bytes have been received
                        progress.receiveBytes(count: 1)
                        bufferCount += 1

                        // Check to see if we've reached the buffer size
                        if bufferCount >= bufferSize {

                            // Co-operative cancellation
                            try Task.checkCancellation()

                            // Yield progress
                            continuation.yield(.progress(progress))

                            // Reset the buffer count
                            bufferCount = 0
                        }
                    } // End of for-await-in bytes

                    // Yield progress
                    continuation.yield(.progress(progress))

                    // Yield the value
                    continuation.yield(
                        .value((data, response), progress)
                    )

                    continuation.finish()

                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
