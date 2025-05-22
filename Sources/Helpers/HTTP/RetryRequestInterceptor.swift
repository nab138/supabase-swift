//
//  RetryRequestInterceptor.swift
//
//
//  Created by Guilherme Souza on 23/04/24.
//

import Foundation


#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// An HTTP client interceptor for retrying failed HTTP requests with exponential backoff.
///
/// The `RetryRequestInterceptor` actor intercepts HTTP requests and automatically retries them in case
/// of failure, with exponential backoff between retries. You can configure the retry behavior by specifying
/// the retry limit, exponential backoff base, scale, retryable HTTP methods, HTTP status codes, and URL error codes.
actor RetryRequestInterceptor: HTTPClientInterceptor {
  /// The default retry limit for the interceptor.
  static let defaultRetryLimit = 2
  /// The default base value for exponential backoff.
  static let defaultExponentialBackoffBase: UInt = 2
  /// The default scale factor for exponential backoff.
  static let defaultExponentialBackoffScale: Double = 0.5

  /// The default set of retryable HTTP methods.
  static let defaultRetryableHTTPMethods: Set<HTTPRequest.Method> = [
    .delete, .get, .head, .options, .put, .trace,
  ]

  /// The default set of retryable URL error codes.
  static let defaultRetryableURLErrorCodes: Set<URLError.Code> = [
    .backgroundSessionInUseByAnotherProcess, .backgroundSessionWasDisconnected,
    .badServerResponse, .callIsActive, .cannotConnectToHost, .cannotFindHost,
    .cannotLoadFromNetwork, .dataNotAllowed, .dnsLookupFailed,
    .downloadDecodingFailedMidStream, .downloadDecodingFailedToComplete,
    .internationalRoamingOff, .networkConnectionLost, .notConnectedToInternet,
    .secureConnectionFailed, .serverCertificateHasBadDate,
    .serverCertificateNotYetValid, .timedOut,
  ]

  /// The default set of retryable HTTP status codes.
  static let defaultRetryableHTTPStatusCodes: Set<Int> = [
    408, 500, 502, 503, 504,
  ]

  /// The maximum number of retries.
  let retryLimit: Int
  /// The base value for exponential backoff.
  let exponentialBackoffBase: UInt
  /// The scale factor for exponential backoff.
  let exponentialBackoffScale: Double
  /// The set of retryable HTTP methods.
  let retryableHTTPMethods: Set<HTTPRequest.Method>
  /// The set of retryable HTTP status codes.
  let retryableHTTPStatusCodes: Set<Int>
  /// The set of retryable URL error codes.
  let retryableErrorCodes: Set<URLError.Code>

  /// Creates a `RetryRequestInterceptor` instance.
  ///
  /// - Parameters:
  ///   - retryLimit: The maximum number of retries. Default is `2`.
  ///   - exponentialBackoffBase: The base value for exponential backoff. Default is `2`.
  ///   - exponentialBackoffScale: The scale factor for exponential backoff. Default is `0.5`.
  ///   - retryableHTTPMethods: The set of retryable HTTP methods. Default includes common methods.
  ///   - retryableHTTPStatusCodes: The set of retryable HTTP status codes. Default includes common status codes.
  ///   - retryableErrorCodes: The set of retryable URL error codes. Default includes common error codes.
  init(
    retryLimit: Int = RetryRequestInterceptor.defaultRetryLimit,
    exponentialBackoffBase: UInt = RetryRequestInterceptor.defaultExponentialBackoffBase,
    exponentialBackoffScale: Double = RetryRequestInterceptor.defaultExponentialBackoffScale,
    retryableHTTPMethods: Set<HTTPRequest.Method> = RetryRequestInterceptor
      .defaultRetryableHTTPMethods,
    retryableHTTPStatusCodes: Set<Int> = RetryRequestInterceptor.defaultRetryableHTTPStatusCodes,
    retryableErrorCodes: Set<URLError.Code> = RetryRequestInterceptor.defaultRetryableURLErrorCodes
  ) {
    precondition(
      exponentialBackoffBase >= 2,
      "The `exponentialBackoffBase` must be a minimum of 2."
    )

    self.retryLimit = retryLimit
    self.exponentialBackoffBase = exponentialBackoffBase
    self.exponentialBackoffScale = exponentialBackoffScale
    self.retryableHTTPMethods = retryableHTTPMethods
    self.retryableHTTPStatusCodes = retryableHTTPStatusCodes
    self.retryableErrorCodes = retryableErrorCodes
  }

  /// Intercepts an HTTP request and automatically retries it in case of failure.
  ///
  /// - Parameters:
  ///   - request: The original HTTP request to be intercepted and retried.
  ///   - next: A closure representing the next interceptor in the chain.
  /// - Returns: The HTTP response obtained after retrying.
  func intercept(
    _ request: SBHTTPRequest,
    next: @Sendable (SBHTTPRequest) async throws -> SBHTTPResponse
  ) async throws -> SBHTTPResponse {
    try await retry(request, retryCount: 1, next: next)
  }

  private func shouldRetry(request: SBHTTPRequest, result: Result<SBHTTPResponse, any Error>) -> Bool {
    guard retryableHTTPMethods.contains(request.method) else { return false }

    if let statusCode = result.value?.statusCode, retryableHTTPStatusCodes.contains(statusCode) {
      return true
    }

    guard let errorCode = (result.error as? URLError)?.code else {
      return false
    }

    return retryableErrorCodes.contains(errorCode)
  }

  private func retry(
    _ request: SBHTTPRequest,
    retryCount: Int,
    next: @Sendable (SBHTTPRequest) async throws -> SBHTTPResponse
  ) async throws -> SBHTTPResponse {
    let result: Result<SBHTTPResponse, any Error>

    do {
      let response = try await next(request)
      result = .success(response)
    } catch {
      result = .failure(error)
    }

    if retryCount < retryLimit, shouldRetry(request: request, result: result) {
      let retryDelay =
        pow(
          Double(exponentialBackoffBase),
          Double(retryCount)
        ) * exponentialBackoffScale

      let nanoseconds = UInt64(retryDelay)
      try? await Task.sleep(nanoseconds: NSEC_PER_SEC * nanoseconds)

      if !Task.isCancelled {
        return try await retry(request, retryCount: retryCount + 1, next: next)
      }
    }

    return try result.get()
  }
}
