import Foundation

private let _version = "2.28.0"  // {x-release-please-version}

let version = _version

private let _platform: String? = {
  #if os(macOS)
    return "macOS"
  #elseif os(iOS)
    #if targetEnvironment(macCatalyst)
      return "macCatalyst"
    #else
      if #available(iOS 14.0, *), ProcessInfo.processInfo.isiOSAppOnMac {
        return "iOSAppOnMac"
      }
      return "iOS"
    #endif
  #elseif os(watchOS)
    return "watchOS"
  #elseif os(tvOS)
    return "tvOS"
  #elseif os(Android)
    return "Android"
  #elseif os(Linux)
    return "Linux"
  #elseif os(Windows)
    return "Windows"
  #else
    return nil
  #endif
}()

private let _platformVersion: String? = {
  #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(Windows)
    let majorVersion = ProcessInfo.processInfo.operatingSystemVersion.majorVersion
    let minorVersion = ProcessInfo.processInfo.operatingSystemVersion.minorVersion
    let patchVersion = ProcessInfo.processInfo.operatingSystemVersion.patchVersion
    return "\(majorVersion).\(minorVersion).\(patchVersion)"
  #elseif os(Linux) || os(Android)
    if let version = try? String(contentsOfFile: "/proc/version") {
      return version.trimmingCharacters(in: .whitespacesAndNewlines)
    } else {
      return nil
    }
  #else
    nil
  #endif
}()

let platform = _platform

let platformVersion = _platformVersion
