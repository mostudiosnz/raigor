import FirebaseCrashlytics
import Foundation
import os
import RegexBuilder
import SwiftUI
import TelemetryDeck

public protocol Logger: Sendable {
    func log(_ log: String)
    func error(_ error: Error)
}

protocol TDLogger {
    init(
        appID: String,
        bundle: Bundle,
        fallbackSubsystem: String,
    )
    func log(_ log: String)
    func error(_ error: Error, userInfo: [String: String])
}

struct TDLoggerAdapter: TDLogger {
    private let logSignalName: String
    private let errorSignalName: String
    private let initialized: Bool
    init(
        appID: String,
        bundle: Bundle = .main,
        fallbackSubsystem: String = "AppLogger",
    ) {
        logSignalName = "log_\(bundle.bundleIdentifier ?? fallbackSubsystem)"
        errorSignalName = "error_\(bundle.bundleIdentifier ?? fallbackSubsystem)"
        initialized = !appID.isEmpty
        guard !appID.isEmpty else { return }
        TelemetryDeck.initialize(config: TelemetryDeck.Config(appID: appID))
    }
    func log(_ log: String) {
        guard initialized else { return }
        TelemetryDeck.signal(
            logSignalName,
            parameters: ["message": log],
            floatValue: nil,
            customUserID: nil,
        )
    }
    func error(_ error: any Error, userInfo: [String: String]) {
        guard initialized else { return }
        TelemetryDeck.errorOccurred(
            id: errorSignalName,
            category: nil,
            message: error.description,
            parameters: userInfo,
            floatValue: nil,
            customUserID: nil,
        )
    }
}

extension Crashlytics: @unchecked @retroactive Sendable {}

/**
 Logs to both `os.Logger` and `Crashlytics`
 */
public actor DefaultLogger: Logger {
    private let osLogger: os.Logger
    private let fbLogger: Crashlytics
    private let tdLogger: TDLoggerAdapter
    public init(
        bundle: Bundle = .main,
        fallbackSubsystem: String = "AppLogger",
        category: String = "Application",
        crashlytics: Crashlytics = .crashlytics(),
        telemetryDeckKey: String = "",
    ) {
        osLogger = os.Logger(subsystem: bundle.bundleIdentifier ?? fallbackSubsystem, category: category)
        fbLogger = crashlytics
        tdLogger = TDLoggerAdapter(appID: telemetryDeckKey)
    }
    nonisolated public func log(_ log: String) {
        #if DEBUG
        osLogger.log("\(log, privacy: .public)")
        #else
        osLogger.log("\(log)")
        #endif
        fbLogger.log(log)
        tdLogger.log(log)
    }
    nonisolated public func error(_ error: Error) {
        #if DEBUG
        osLogger.error("\(error.description, privacy: .public)")
        #else
        osLogger.error("\(error.description)")
        #endif
        let callStack = createCallStackSymbols()
        fbLogger.record(error: error, userInfo: callStack)
        tdLogger.error(error, userInfo: callStack)
    }
    nonisolated func createCallStackSymbols() -> [String: String] {
        guard #available(iOS 16.0, macOS 13.0, *) else { return [:] }
        let regex = Regex {
            Capture({ OneOrMore(.digit) }, transform: { Int($0) ?? -1 })
            OneOrMore(.whitespace)
            Capture{ OneOrMore(.word) }
            OneOrMore(.whitespace)
            Capture{ OneOrMore(.anyNonNewline) }
        }
        return Thread.callStackSymbols.compactMap { try? regex.firstMatch(in: $0) }
            .reduce([:] as [String: String], { dict, result in
                let key = "\(result.1) \(result.2)"
                let value = "\(result.3)"
                return dict.merging([key: value], uniquingKeysWith: { $1 })
            })
    }
}

private extension Error {
    var description: String {
        (self as NSError).description
    }
}
