//
//  HTTPResponse.swift
//
//
//  Created by Guilherme Souza on 30/04/24.
//

import Foundation


#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

struct SBHTTPResponse: Sendable {
  let data: Data
  let headers: HTTPFields
  let statusCode: Int

  let underlyingResponse: HTTPURLResponse

  init(data: Data, response: HTTPURLResponse) {
    self.data = data
    headers = HTTPFields(response.allHeaderFields as? [String: String] ?? [:])
    statusCode = response.statusCode
    underlyingResponse = response
  }
}

extension SBHTTPResponse {
  func decoded<T: Decodable>(as _: T.Type = T.self, decoder: JSONDecoder = JSONDecoder()) throws -> T {
    try decoder.decode(T.self, from: data)
  }
}
