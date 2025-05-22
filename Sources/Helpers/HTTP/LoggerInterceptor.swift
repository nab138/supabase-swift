//
//  LoggerInterceptor.swift
//
//
//  Created by Guilherme Souza on 30/04/24.
//

import Foundation

struct LoggerInterceptor: HTTPClientInterceptor {
  let logger: any SupabaseLogger

  init(logger: any SupabaseLogger) {
    self.logger = logger
  }

  func intercept(
    _ request: SBHTTPRequest,
    next: @Sendable (SBHTTPRequest) async throws -> SBHTTPResponse
  ) async throws -> SBHTTPResponse {
    let id = UUID().uuidString
    return try await SupabaseLoggerTaskLocal.$additionalContext.withValue(merging: ["requestID": .string(id)]) {
      let urlRequest = request.urlRequest

      logger.verbose(
        """
        Request: \(urlRequest.httpMethod ?? "") \(urlRequest.url?.absoluteString.removingPercentEncoding ?? "")
        Body: \(stringfy(request.body))
        """
      )

      do {
        let response = try await next(request)
        logger.verbose(
          """
          Response: Status code: \(response.statusCode) Content-Length: \(
            response.underlyingResponse.expectedContentLength
          )
          Body: \(stringfy(response.data))
          """
        )
        return response
      } catch {
        logger.error("Response: Failure \(error)")
        throw error
      }
    }
  }
}

func stringfy(_ data: Data?) -> String {
  guard let data else {
    return "<none>"
  }

  do {
    let object = try JSONSerialization.jsonObject(with: data, options: [])
    let prettyData = try JSONSerialization.data(
      withJSONObject: object,
      options: [.prettyPrinted, .sortedKeys]
    )
    return String(data: prettyData, encoding: .utf8) ?? "<failed>"
  } catch {
    return String(data: data, encoding: .utf8) ?? "<failed>"
  }
}
