import Foundation
import CryptoKit

struct PKCE {
  var generateCodeVerifier: @Sendable () -> String
  var generateCodeChallenge: @Sendable (_ codeVerifier: String) -> String
}

extension PKCE {
  static let live = PKCE(
    generateCodeVerifier: {
      let buffer = (0..<64).map { _ in UInt8.random(in: 0...255) }
      return Data(buffer).pkceBase64EncodedString()
    },
    generateCodeChallenge: { codeVerifier in
      guard let data = codeVerifier.data(using: .utf8) else {
        preconditionFailure("provided string should be utf8 encoded.")
      }
      let hashed = Data(SHA256.hash(data: data))
      return hashed.pkceBase64EncodedString()
    }
  )
}

extension Data {
  // Returns a base64 encoded string, replacing reserved characters
  // as per the PKCE spec https://tools.ietf.org/html/rfc7636#section-4.2
  func pkceBase64EncodedString() -> String {
    base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
      .trimmingCharacters(in: .whitespaces)
  }
}
