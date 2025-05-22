import Foundation


public struct RealtimeMessageV2: Codable, Sendable {
  public let joinRef: String?
  public let ref: String?
  public let topic: String
  public let event: String
  public let payload: JSONObject

  public init(joinRef: String?, ref: String?, topic: String, event: String, payload: JSONObject) {
    self.joinRef = joinRef
    self.ref = ref
    self.topic = topic
    self.event = event
    self.payload = payload
  }

  /// Status for the received message if any.
  public var status: PushStatus? {
    payload["status"]
      .flatMap(\.stringValue)
      .flatMap(PushStatus.init(rawValue:))
  }

  @available(
    *, deprecated,
    message: "Access to event type will be removed, please inspect raw event value instead."
  )
  public var eventType: EventType? { _eventType }

  var _eventType: EventType? {
    switch event {
    case ChannelEvent.system:
      return .system
    case ChannelEvent.postgresChanges:
      return .postgresChanges
    case ChannelEvent.broadcast:
      return .broadcast
    case ChannelEvent.close:
      return .close
    case ChannelEvent.error:
      return .error
    case ChannelEvent.presenceDiff:
      return .presenceDiff
    case ChannelEvent.presenceState:
      return .presenceState
    case ChannelEvent.reply:
      return .reply
    default:
      return nil
    }
  }

  public enum EventType {
    case system
    case postgresChanges
    case broadcast
    case close
    case error
    case presenceDiff
    case presenceState
    @available(
      *, deprecated,
      message:
        "tokenExpired gets returned as system, check payload for verifying if is a token expiration."
    )
    case tokenExpired
    case reply
  }

  private enum CodingKeys: String, CodingKey {
    case joinRef = "join_ref"
    case ref
    case topic
    case event
    case payload
  }
}

extension RealtimeMessageV2: HasRawMessage {
  public var rawMessage: RealtimeMessageV2 { self }
}
