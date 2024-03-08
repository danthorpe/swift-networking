# Swift Networking
[![Tests](https://github.com/danthorpe/swift-networking/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/danthorpe/swift-networking/actions/workflows/ci.yml)

Swift Networking, or `swift-networking`, is a library for building a flexible network stack inside a Swift application. It can be used on any Apple platform. You can use to provide rich network features such as authenticating, de-duping, throttling and many more.

* [What is Swift Networking?](#what-is-swift-networking?)
* [Deep Dive](#deep-dive)

## What is Swift Networking?
Swift Networking is a Swift Package, which provides some core tools used to make HTTP network requests. 

It's philosophy is centered around the idea that at a high level clients send requests, and await a response. This is effectively a transformation of data types. With this in-mind, the library provides components which can be composed together to perform this transformation. All of the built-in components are well tested, with test helpers to make it easy to test your own custom components.

### Why not just use URLSession?
This library makes use of URLSession, as it provides the _terminal component_ which is ultimately responsible for sending the request. Swift Networking abstracts this detail away, while also providing a lot more functionality than URLSession does.

## Deep Dive
If we consider that when a client makes a network request, it is essentially a function: `(Request) async throws -> Response`. We can represent this through a protocol, called `NetworkingComponent`. We can provide a conformance to this protocol on `URLSession`, and use it make network requests. However, before the request is given to `URLSession` there is opportunity to transform it further, perhaps it needs to be modified, or we wish to collect metrics, or maybe even return the Response from another system.

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
