//
//  Copyright © 2022 Daniel Thorpe. All rights reserved.
//

/// Inspired by Dave de Long's blog series on HTTP
/// https://davedelong.com/blog/2020/06/27/http-in-swift-part-1/

import Foundation

public struct HTTPStatus: Hashable {
    public static let `continue`: Self                      = 100
    public static let switchingProtocols: Self              = 101
    public static let processing: Self                      = 102
    public static let earlyHints: Self                      = 103

    public static let ok: Self                              = 200
    public static let created: Self                         = 201
    public static let accepted: Self                        = 202
    public static let nonAuthoritativeInformation: Self     = 203
    public static let noContent: Self                       = 204
    public static let resetContent: Self                    = 205
    public static let partialContent: Self                  = 206
    public static let multiStatus: Self                     = 207
    public static let alreadyReported: Self                 = 208
    public static let imUsed: Self                          = 226

    public static let multipleChoices: Self                 = 300
    public static let movedPermanently: Self                = 301
    public static let found: Self                           = 302
    public static let seeOther: Self                        = 303
    public static let notModified: Self                     = 304
    public static let useProxy: Self                        = 305
    public static let switchProxy: Self                     = 306
    public static let temporaryRedirect: Self               = 307
    public static let permanentRedirect: Self               = 308

    public static let badRequest: Self                      = 400
    public static let unauthorized: Self                    = 401
    public static let paymentRequired: Self                 = 402
    public static let forbidden: Self                       = 403
    public static let notFound: Self                        = 404
    public static let methodNotAllowed: Self                = 405
    public static let notAcceptable: Self                   = 406
    public static let proxyAuthenticationRequired: Self     = 407
    public static let requestTimeout: Self                  = 408
    public static let conflict: Self                        = 409
    public static let gone: Self                            = 410
    public static let lengthRequired: Self                  = 411
    public static let preconditionFailed: Self              = 412
    public static let payloadTooLarge: Self                 = 413
    public static let uriTooLong: Self                      = 414
    public static let unsupportedMediaType: Self            = 415
    public static let rangeNotSatisfiable: Self             = 416
    public static let expectationFailed: Self               = 417
    public static let teapot: Self                          = 418
    public static let misdirectedRequest: Self              = 421
    public static let unprocessableEntity: Self             = 422
    public static let locked: Self                          = 423
    public static let failedDependency: Self                = 424
    public static let tooEarly: Self                        = 425
    public static let upgradeRequired: Self                 = 426
    public static let preconditionRequired: Self            = 428
    public static let tooManyRequests: Self                 = 429
    public static let requestHeaderFieldsTooLarge: Self     = 430
    public static let unavailableForLegalReasons: Self      = 431

    public static let internalServerError: Self             = 500
    public static let notImplemented: Self                  = 501
    public static let badGateway: Self                      = 502
    public static let serviceUnavailable: Self              = 503
    public static let gatewayTimeout: Self                  = 504
    public static let httpVersionNotSupported: Self         = 505
    public static let variantAlsoNegotiates: Self           = 506
    public static let insufficientStorage: Self             = 507
    public static let loopDetected: Self                    = 508
    public static let notExtended: Self                     = 510
    public static let networkAuthenticationRequired: Self   = 511

    public init(_ code: Int) {
        self.code = code
    }

    public let code: Int
}


extension HTTPStatus: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self.init(value)
    }
}

extension HTTPStatus {
    var success: Bool {
        (Self.ok.code..<Self.multipleChoices.code).contains(code)
    }
}
