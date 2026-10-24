# Raigor

A wrapper around OSLog, [Firebase Crashlytics](https://github.com/firebase/firebase-ios-sdk), and [Mixpanel](https://github.com/mixpanel/mixpanel-swift) for logging used throughout MO Studios iOS projects.

## Install

Use Swift Package Manager to install. Requires Xcode 26.2 or later (Swift 6.2.3+), iOS 15+, macOS 11+, tvOS 15+, or watchOS 8+.

Firebase is pinned to 13.1.1. Mixpanel is pinned to 6.8.0 to retain macOS 11 and watchOS 8 support; Mixpanel 7 requires macOS 12 and watchOS 9.

## Usage

Create an `AppLogger` instance and use it throughout the app. Recommended approach is to set it on the environment and use it throughout the app, but it can be constructed whenever as it is stateless.

```
// SomeView.swift

import SwiftUI

struct AppLoggerKey: EnvironmentKey {
    static let defaultValue: any Logger = AppLogger()
}

extension EnvironmentValues {
    var logger: any Logger {
        get { self[AppLoggerKey.self] }
        set { self[AppLoggerKey.self] = newValue }
    }
}

struct SomeView: View {
  @Environment(\.logger) var logger
  var body: some View {
    VStack {
      ...
    }.onAppear {
      logger.log("SomeView appeared")
    }
  }
}
```
