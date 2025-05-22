//
//  RealtimeChannel+AsyncAwait.swift
//
//
//  Created by Guilherme Souza on 17/04/24.
//

import Foundation

extension RealtimeChannelV2 {
  /// Listen for clients joining / leaving the channel using presences.
  public func presenceChange() -> AsyncStream<any PresenceAction> {
    AsyncStream<any PresenceAction> { continuation in
      let subscription = onPresenceChange {
        continuation.yield($0)
      }
      continuation.onTermination = { @Sendable _ in
        subscription.cancel()
      }
    }
  }

  /// Listen for postgres changes in a channel.
  public func postgresChange(
    _: InsertAction.Type,
    schema: String = "public",
    table: String? = nil,
    filter: RealtimePostgresFilter? = nil
  ) -> AsyncStream<InsertAction> {
    postgresChange(event: .insert, schema: schema, table: table, filter: filter?.value)
      .compactErase()
  }

  /// Listen for postgres changes in a channel.
  @available(
    *,
     deprecated,
     message: "Use the new filter syntax instead."
  )
  @_disfavoredOverload
  public func postgresChange(
    _: InsertAction.Type,
    schema: String = "public",
    table: String? = nil,
    filter: String? = nil
  ) -> AsyncStream<InsertAction> {
    postgresChange(event: .insert, schema: schema, table: table, filter: filter)
      .compactErase()
  }

  /// Listen for postgres changes in a channel.
  public func postgresChange(
    _: UpdateAction.Type,
    schema: String = "public",
    table: String? = nil,
    filter: RealtimePostgresFilter? = nil
  ) -> AsyncStream<UpdateAction> {
    postgresChange(event: .update, schema: schema, table: table, filter: filter?.value)
      .compactErase()
  }

  /// Listen for postgres changes in a channel.
  @available(
    *,
     deprecated,
     message: "Use the new filter syntax instead."
  )
  @_disfavoredOverload
  public func postgresChange(
    _: UpdateAction.Type,
    schema: String = "public",
    table: String? = nil,
    filter: String? = nil
  ) -> AsyncStream<UpdateAction> {
    postgresChange(event: .update, schema: schema, table: table, filter: filter)
      .compactErase()
  }

  /// Listen for postgres changes in a channel.
  public func postgresChange(
    _: DeleteAction.Type,
    schema: String = "public",
    table: String? = nil,
    filter: RealtimePostgresFilter? = nil
  ) -> AsyncStream<DeleteAction> {
    postgresChange(event: .delete, schema: schema, table: table, filter: filter?.value)
      .compactErase()
  }

  /// Listen for postgres changes in a channel.
  @available(
    *,
     deprecated,
     message: "Use the new filter syntax instead."
  )
  @_disfavoredOverload
  public func postgresChange(
    _: DeleteAction.Type,
    schema: String = "public",
    table: String? = nil,
    filter: String? = nil
  ) -> AsyncStream<DeleteAction> {
    postgresChange(event: .delete, schema: schema, table: table, filter: filter)
      .compactErase()
  }

  /// Listen for postgres changes in a channel.
  public func postgresChange(
    _: AnyAction.Type,
    schema: String = "public",
    table: String? = nil,
    filter: RealtimePostgresFilter? = nil
  ) -> AsyncStream<AnyAction> {
    postgresChange(event: .all, schema: schema, table: table, filter: filter?.value)
  }

  /// Listen for postgres changes in a channel.
  @available(
    *,
     deprecated,
     message: "Use the new filter syntax instead."
  )
  @_disfavoredOverload
  public func postgresChange(
    _: AnyAction.Type,
    schema: String = "public",
    table: String? = nil,
    filter: String? = nil
  ) -> AsyncStream<AnyAction> {
    postgresChange(event: .all, schema: schema, table: table, filter: filter)
  }

  private func postgresChange(
    event: PostgresChangeEvent,
    schema: String,
    table: String?,
    filter: String?
  ) -> AsyncStream<AnyAction> {
    AsyncStream<AnyAction> { continuation in
      let subscription = _onPostgresChange(
        event: event,
        schema: schema,
        table: table,
        filter: filter
      ) {
        continuation.yield($0)
      }
      continuation.onTermination = { @Sendable _ in
        subscription.cancel()
      }
    }
  }

  /// Listen for broadcast messages sent by other clients within the same channel under a specific `event`.
  public func broadcastStream(event: String) -> AsyncStream<JSONObject> {
    AsyncStream<JSONObject> { continuation in
      let subscription = onBroadcast(event: event) {
        continuation.yield($0)
      }
      continuation.onTermination = { @Sendable _ in
        subscription.cancel()
      }
    }
  }
  
  /// Listen for `system` event.
  public func system() -> AsyncStream<RealtimeMessageV2> {
    AsyncStream<RealtimeMessageV2> { continuation in
      let subscription = onSystem {
        continuation.yield($0)
      }
      continuation.onTermination = { @Sendable _ in
        subscription.cancel()
      }
    }
  }

  /// Listen for broadcast messages sent by other clients within the same channel under a specific `event`.
  @available(*, deprecated, renamed: "broadcastStream(event:)")
  public func broadcast(event: String) -> AsyncStream<JSONObject> {
    broadcastStream(event: event)
  }
}

// Helper to work around type ambiguity in macOS 13
fileprivate extension AsyncStream<AnyAction> {
  func compactErase<T: Sendable>() -> AsyncStream<T> {
    AsyncStream<T>(compactMap { $0.wrappedAction as? T } as AsyncCompactMapSequence<Self, T>)
  }
}
