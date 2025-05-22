//
//  SBHTTPRequest.swift
//
//
//  Created by Guilherme Souza on 23/04/24.
//

import Foundation


#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

struct SBHTTPRequest: Sendable {
  var url: URL
  var method: HTTPRequest.Method
  var query: [URLQueryItem]
  var headers: HTTPFields
  var body: Data?

  enum Method: String, Sendable {
    case get, post, put, delete, patch, head, options, trace
  }

  init(
    url: URL,
    method: HTTPRequest.Method,
    query: [URLQueryItem] = [],
    headers: HTTPFields = [:],
    body: Data? = nil
  ) {
    self.url = url
    self.method = method
    self.query = query
    self.headers = headers
    self.body = body
  }

  init?(
    urlString: String,
    method: HTTPRequest.Method,
    query: [URLQueryItem] = [],
    headers: HTTPFields = [:],
    body: Data?
  ) {
    guard let url = URL(string: urlString) else { return nil }
    self.init(url: url, method: method, query: query, headers: headers, body: body)
  }

  var urlRequest: URLRequest {
    var urlRequest = URLRequest(url: query.isEmpty ? url : url.appendingQueryItems(query))
    urlRequest.httpMethod = method.rawValue
    urlRequest.allHTTPHeaderFields = .init(headers.map { ($0.name.rawName, $0.value) }) { $1 }
    urlRequest.httpBody = body

    if urlRequest.httpBody != nil, urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
      urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }

    return urlRequest
  }
}

extension [URLQueryItem] {
  mutating func appendOrUpdate(_ queryItem: URLQueryItem) {
    if let index = firstIndex(where: { $0.name == queryItem.name }) {
      self[index] = queryItem
    } else {
      self.append(queryItem)
    }
  }
}
