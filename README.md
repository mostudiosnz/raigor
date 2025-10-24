# Raigor

A wrapper around [FirebaseAnalytics](https://github.com/firebase/firebase-ios-sdk) and [TelemetryDeck](https://github.com/TelemetryDeck/SwiftSDK)  for logging used throughout MO Studios iOS projects.

## Install

Use Swift Package Manager to install.

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
