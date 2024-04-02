# ``NetworkingComponent/data(_:progress:)``

Access the response as raw data.

Execute a request and await the raw response.

This function works by sending the request, and awaiting over the stream of
values. Periodically it will call the provided progress closure with an updated
``BytesReceived`` value. This allows easy display of progress. The frequency of
this progress depends on the upstream networking component. By default, when using
URLSession this is every 16KB.

The function will throw an error if a timeout is reached before the end of
the response stream. The timeout value is provided via the request option
``HTTPRequestData/requestTimeoutInSeconds`` which defaults to 60 seconds.

This can be configured before sending the request if desired.
