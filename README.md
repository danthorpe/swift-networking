# Swift Networking
[![Tests](https://github.com/danthorpe/swift-networking/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/danthorpe/swift-networking/actions/workflows/ci.yml)

Swift Networking, or `swift-networking`, is a library for building a flexible network stack inside a Swift application. It can be used on any Apple platform. You can use to provide rich network features such as authenticating, de-duping, throttling and many more.

* [What is Swift Networking?](#what-is-swift-networking?)
* [Deep Dive](#deep-dive)
* [Built-in Components](#built-in-components)

## What is Swift Networking?
Swift Networking is a Swift Package, which provides some core tools used to make HTTP network requests. 

It's philosophy is centered around the idea that at a high level clients send requests, and await a response. This is effectively a transformation of data types. With this in-mind, the library provides components which can be composed together to perform this transformation. All of the built-in components are well tested, with test helpers to make it easy to test your own custom components.

### Why not just use URLSession?
This library makes use of URLSession, as it provides the _terminal component_ which is ultimately responsible for sending the request. Swift Networking abstracts this detail away, while also providing a lot more functionality than URLSession does.

## Deep Dive
If we consider that when a client makes a network request, it is essentially a function: `(Request) async throws -> Response`, which can be represented through a protocol, called `NetworkingComponent`. We can provide a conformance to this protocol on `URLSession`, and use it make network requests. However, before the request is given to `URLSession` there is opportunity to transform it further, perhaps it needs to be modified, or we wish to collect metrics, or maybe even return the Response from another system.

Taking this concept a bit further, we can consider a chain of components,

```
                 ┌────────────────────────────────────────────┐                
                 │               Network Stack                │      ┌────────┐
┌─────────┐      │ ┌─────────┐    ┌─────────┐    ┌──────────┐ │      │        │
│ Request │─ ─ ─▶│ │    A    │───▶│    B    │───▶│ Terminal │ │─ ─ ─▶│ Server │
└─────────┘      │ └─────────┘    └─────────┘    └──────────┘ │      │        │
                 └────────────────────────────────────────────┘      └────────┘
```
in this diagram, the application (or client) has 3 components: `A`, `B` and `Terminal`. When a request is provided to the overall stack, it starts in component A, which eventually gives it to component B, which eventually gives it to the terminal component, which is the last component and responsible for getting the response. The response from the server travels back through the stack.

To make this composition easy, the library provides a `NetworkingModifier` protocol, which works exactly like `ViewModifier` from SwiftUI. All networking components except the terminal one are actually modifiers, so that in addition to the `Request` value, they also receive the "upstream" networking component. This is how it is possible for component A to _pass_ the request onto component B etc.

Each of the built-in components provide public extensions on `NetworkingComponent`, just as ViewModifiers in SwiftUI typically provide an API through extensions to the `View` protocol. This results in a declarative network stack, something like this:

```swift
let network = URLSession.shared
  .removeDuplicates()
  .logged()
```

Updating our diagram from above, we can see that the network stack enables us to connect components together, feed in requests, and get responses out.

```
 ┌─────────┐                                                                     
 │ Request │─ ─ ─▶┌────────────────────────────────────────────┐                 
 └─────────┘      │               Network Stack                │       ┌────────┐
                  │ ┌─────────┐───▶┌─────────┐───▶┌──────────┐ │       │        │
                  │ │ Logged  │    │ De-dupe │    │URLSession│ │◀─ ─ ─▶│ Server │
┌──────────┐      │ └─────────┘◀───└─────────┘◀───└──────────┘ │       │        │
│ Response │◀ ─ ─ └────────────────────────────────────────────┘       └────────┘
└──────────┘
```

## Built-in Components

The library ships with the following built-in components.
- `Authentication` Can we used to handle network authentication. This is probably the most complex component, and it's usage in an application requires a delegate conformance. Currently supported are Basic and Bearer authentication methods. Future enhancement will be to support OAuth etc. 
- `Cached` Can be used to cache network responses in memory. A future enhancement would be to support different cache backend systems.
- `CheckedStatusCode` This is a simple component to sanitise error handling to pick out some basic cases. Currently it is open for customisation, so it more useful as an internal component, but a future enhancement could allow it to be used for custom error handling.
- `Delayed` Delay requests by a fixed `Duration`. This uses the Swift continuous clock, and it very testable. 
- `DuplicatesRemoved` The network stack allows concurrent network requests, meaning that it is possible for multiple requests to be active at the same time. This component will prevent any duplicate requests firing, and share the response of the only request executed with all duplicate requests. Be careful with this, it might mask underlying application errors.
- `Logged` Although fully customisable, this component has sensible defaults to log info about requests as they start and finish using a `Logger`. Additionally, underlying types have properties to enable pretty printing.
- `Metrics` This can be included in your network stack to instrument its performance. It can report the overall elapsed time of each request, including a breakdown for each component (which support instrumentation). Currently this just logs metrics to the console. A future improvement would allow a richer reporting mechanism, including session statistics.
- `Numbered` Adds a monotonically increasing number of every request sent in the current session, i.e. from when the stack is initialised. This is quite handy for logging and debugging. It's also worth noting, that the basic HTTP request type, `HTTPRequestData` uniquely identifies each request too.
- `Retry` Automatically retry failed requests. By default each request is retried up to 3 times each after a constant delay of 3 seconds. This can be configured for each request however, with constant, immediate or exponential strategies available. Or create your own by conforming to `RetryingStrategy`.
- `Server` A building block component to configure all requests which are sent via the stack. For example, set default request headers, base URL, scheme etc. Typically this allows your application to create just the specific aspects of each request, such as query parameters or body values. Yet all requests will get the default request parameters as configured by the stack. This component can also be chained together, so typically it is used many times which makes each line/invocation a readable and maintainable point of your configuration. Generally speaking, it is best to add the server components after logging, so that they are included in the logged info.
- `Throttled` Can be used to limit the number of concurrent requests. This is very helpful to protect your backend from situations where user behaviour could flood the servers. Additionally requests are added to an internal queue. 
- `URLSession` Currently the only terminal component is for URLSession. Future transports which would fit the request/response could be supported in the future.
