import Foundation
import URLRouting

public struct NetworkStack {
    var data: (URLRequest, Progress?) async throws -> (Data, URLResponse)

    public init(
        data: @escaping (URLRequest, Progress?) async throws -> (Data, URLResponse)
    ) {
        self.data = data
    }
}

extension NetworkStack {

    public static func use(session: URLSession) -> Self {
        .init(
            data: { (request, progress) in
                var dataTask: URLSessionDataTask?
                let cancel: () -> Void = { dataTask?.cancel() }

                return try await withTaskCancellationHandler(
                    handler: { cancel() },
                    operation: {
                        try await withCheckedThrowingContinuation { continuation in
                            dataTask = session.dataTask(with: request) { data, response, error in
                                guard let data = data, let response = response else {
                                    continuation.resume(throwing: error ?? URLError(.badServerResponse))
                                    return
                                }

                                continuation.resume(returning: (data, response))
                            }

                            // Attach the data task's progress as a child progress to the parent
                            if let parent = progress, let child = dataTask?.progress {
                                parent.addChild(child, withPendingUnitCount: 1)
                            }

                            // Resume the data task
                            dataTask?.resume()
                        }
                    }
                )
            }
        )
    }
}

// MARK: - Network Stackable

extension NetworkStack: NetworkStackable {
    public func data(_ requestData: URLRequestData) async throws -> URLResponseData {
        guard let urlRequest = URLRequest(data: requestData) else {
            throw NetworkingError(.invalidRequest(.url), request: requestData)
        }
        do {
            let (data, urlResponse) = try await data(urlRequest, nil)
            return try URLResponseData(
                request: requestData,
                data: data,
                response: urlResponse
            )
        } catch {
            throw NetworkingError(request: requestData, other: error)
        }
    }
}
