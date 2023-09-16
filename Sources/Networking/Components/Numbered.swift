extension NetworkingComponent {
    public func numbered() -> some NetworkingComponent {
        modified(Numbered())
    }
}

public struct RequestSequence {
    @TaskLocal
    public static var number: Int = 0
}

struct Numbered: NetworkingModifier {
    private let sequence = SequenceNumber(value: 0)

    func send(upstream: NetworkingComponent, request: HTTPRequestData) -> ResponseStream<HTTPResponseData> {
        ResponseStream<HTTPResponseData> { continuation in
            Task {
                await RequestSequence.$number.withValue(sequence.next()) {
                    await upstream.send(request).redirect(into: continuation)
                }
            }
        }
    }
}

actor SequenceNumber {
    @TaskLocal
    static var next: @Sendable (Int) -> Int = { $0 + 1 }

    private var value: Int

    init(value: Int) {
        self.value = value
    }

    func next() -> Int {
        value = Self.next(value)
        return value
    }
}
