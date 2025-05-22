import Foundation


/// A value that can be used to filter Postgrest queries.
public protocol PostgrestFilterValue {
  var rawValue: String { get }
}

extension PostgrestFilterValue {
  @available(*, deprecated, renamed: "rawValue")
  public var queryValue: String { rawValue }
}

extension String: PostgrestFilterValue {}

extension Int: PostgrestFilterValue {}

extension Double: PostgrestFilterValue {}

extension Bool: PostgrestFilterValue {}

extension UUID: PostgrestFilterValue {}

extension Date: PostgrestFilterValue {}

extension Array: PostgrestFilterValue where Element: PostgrestFilterValue {
  public var rawValue: String {
    return "{\(map(\.rawValue).joined(separator: ","))}"
  }
}

extension AnyJSON: PostgrestFilterValue {
  public var rawValue: String {
    switch self {
    case let .array(array): return array.rawValue
    case let .object(object): return object.rawValue
    case let .string(string): return string.rawValue
    case let .double(double): return double.rawValue
    case let .integer(integer): return integer.rawValue
    case let .bool(bool): return bool.rawValue
    case .null: return "NULL"
    }
  }
}

extension Optional: PostgrestFilterValue where Wrapped: PostgrestFilterValue {
  public var rawValue: String {
    if let value = self {
      return value.rawValue
    }

    return "NULL"
  }
}

extension JSONObject: PostgrestFilterValue {
  public var rawValue: String {
    let value = mapValues(\.value)
    return JSONSerialization.stringfy(value)!
  }
}

extension JSONSerialization {
  static func stringfy(_ object: Any) -> String? {
    let data = try? data(
      withJSONObject: object, options: [.withoutEscapingSlashes, .sortedKeys]
    )
    return data.flatMap { String(data: $0, encoding: .utf8) }
  }
}
