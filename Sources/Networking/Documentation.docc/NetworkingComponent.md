# ``Networking/NetworkingComponent``

The network stack is comprised of mulitple elements using a chain-of-responsibility style. Each element conforms to the ``NetworkingComponent`` protocol.

## Overview

This is a key building block of the library. When using a network stack, it is exposed as `some NetworkingComponent`. This means that the API used to construct a network stack from discrete components is enabled via extensions on ``NetworkingComponent``. Additionally, the API used by an application to make network requests is also defined on this protocol.

## Topics

### Accessing Data

- ``NetworkingComponent/data(_:progress:)``
- ``NetworkingComponent/data(_:progress:timeout:)``

### Accessing Codable Values

- ``NetworkingComponent/value(_:)``
- ``NetworkingComponent/value(_:as:decoder:)``

### Configuring the behaviour of the Network Stack

- ``NetworkingComponent/automaticRetry()``
- ``NetworkingComponent/delayed(by:)``
- ``NetworkingComponent/duplicatesRemoved()``
- ``NetworkingComponent/numbered()``
- ``NetworkingComponent/throttled(max:)``

### Configuring the Network Stack for your Server

- ``NetworkingComponent/server(authority:)``
- ``NetworkingComponent/server(headerField:_:)``
- ``NetworkingComponent/server(customHeaderField:_:)``
- ``NetworkingComponent/server(path:)``
- ``NetworkingComponent/server(prefixPath:delimiter:)``
- ``NetworkingComponent/server(queryItemsAllowedCharacters:)``
- ``NetworkingComponent/server(scheme:)``
- ``NetworkingComponent/server(mutate:with:log:)``
- ``NetworkingComponent/server(mutateRequest:)``

### Create a Custom Component

To create a custom component, conform to `NetworkingComponent`, and implement the `send` function.

- ``NetworkingComponent/send(_:)``
- ``NetworkingComponent/resolve(_:)``
