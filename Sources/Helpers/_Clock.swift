//
//  _Clock.swift
//  Supabase
//
//  Created by Guilherme Souza on 08/01/25.
//

import Foundation

public protocol _Clock: Sendable {
  func sleep(for duration: TimeInterval) async throws
}

@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
extension ContinuousClock: _Clock {
  public func sleep(for duration: TimeInterval) async throws {
    try await sleep(until: .now.advanced(by: .microseconds(Int(duration * 1_000_000))))
  }
}
@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
extension TestClock<Duration>: _Clock {
  public func sleep(for duration: TimeInterval) async throws {
    try await sleep(until: self.now.advanced(by: .microseconds(Int(duration * 1_000_000))))
  }
}

/// `_Clock` used on platforms where ``Clock`` protocol isn't available.
struct FallbackClock: _Clock {
  func sleep(for duration: TimeInterval) async throws {
    try await Task.sleep(nanoseconds: NSEC_PER_SEC * UInt64(duration))
  }
}

// Resolves clock instance based on platform availability.
let _resolveClock: @Sendable () -> any _Clock = {
  if #available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *) {
    return ContinuousClock()
  } else {
    return FallbackClock()
  }
}

private let __clock = LockIsolated(_resolveClock())

#if DEBUG
  public var _clock: any _Clock {
    get {
      __clock.value
    }
    set {
      __clock.setValue(newValue)
    }
  }
#else
  public var _clock: any _Clock {
    __clock.value
  }
#endif
