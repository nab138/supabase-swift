//
//  HTTPClient.swift
//
//
//  Created by Guilherme Souza on 30/04/24.
//

import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

protocol HTTPClientType: Sendable {
  func send(_ request: SBHTTPRequest) async throws -> SBHTTPResponse
}

actor HTTPClient: HTTPClientType {
  let fetch: @Sendable (URLRequest) async throws -> (Data, URLResponse)
  let interceptors: [any HTTPClientInterceptor]

  init(
    fetch: @escaping @Sendable (URLRequest) async throws -> (Data, URLResponse),
    interceptors: [any HTTPClientInterceptor]
  ) {
    self.fetch = fetch
    self.interceptors = interceptors
  }

  func send(_ request: SBHTTPRequest) async throws -> SBHTTPResponse {
    var next: @Sendable (SBHTTPRequest) async throws -> SBHTTPResponse = { _request in
      let urlRequest = _request.urlRequest
      let (data, response) = try await self.fetch(urlRequest)
      guard let httpURLResponse = response as? HTTPURLResponse else {
        throw URLError(.badServerResponse)
      }
      return SBHTTPResponse(data: data, response: httpURLResponse)
    }

    for interceptor in interceptors.reversed() {
      let tmp = next
      next = {
        try await interceptor.intercept($0, next: tmp)
      }
    }

    return try await next(request)
  }
}

protocol HTTPClientInterceptor: Sendable {
  func intercept(
    _ request: SBHTTPRequest,
    next: @Sendable (SBHTTPRequest) async throws -> SBHTTPResponse
  ) async throws -> SBHTTPResponse
}
