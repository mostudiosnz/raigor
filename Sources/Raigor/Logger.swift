import FirebaseCrashlytics
import Foundation
import os
import RegexBuilder
import SwiftUI
import Mixpanel

public protocol Logger: Sendable {
    func log(_ log: String)
    func error(_ error: Error)
}

protocol MPLogger: Sendable {
    func log(_ log: String)
    func error(_ error: Error, userInfo: [String: String])
}

struct MPLoggerAdapter: MPLogger {
    private let logEventName: String
    private let errorEventName: String
    private let enabled: Bool
    private let instance: MixpanelInstance?
    init(
        enabled mpEnabled: Bool = true,
        bundle: Bundle = .main,
        fallbackSubsystem: String = "AppLogger",
        mixpanelInstance: MixpanelInstance? = Mixpanel.safeMainInstance(),
    ) {
        logEventName = "log.\(bundle.bundleIdentifier ?? fallbackSubsystem)"
        errorEventName = "error.\(bundle.bundleIdentifier ?? fallbackSubsystem)"
        enabled = mpEnabled
        instance = mixpanelInstance
    }
    func log(_ log: String) {
        guard enabled else { return }
        instance?.track(event: logEventName, properties: ["message": log])
    }
    func error(_ error: any Error, userInfo: [String: String]) {
        guard enabled else { return }
        let properties = userInfo.merging(["error": error.description], uniquingKeysWith: { _, new in new })
        instance?.track(event: errorEventName, properties: properties)
    }
}

extension Crashlytics: @unchecked @retroactive Sendable {}
extension MixpanelInstance: @unchecked @retroactive Sendable {}

/**
 Logs to both `os.Logger` and `Crashlytics`
 */
public struct AppLogger: Logger {
    private let osLogger: os.Logger
    private let fbLogger: Crashlytics
    private let mpLogger: MPLogger
    public init(
        bundle: Bundle = .main,
        fallbackSubsystem: String = "AppLogger",
        category: String = "Application",
        crashlytics: Crashlytics = .crashlytics(),
        mixpanelEnabled mpEnabled: Bool = true,
    ) {
        osLogger = os.Logger(subsystem: bundle.bundleIdentifier ?? fallbackSubsystem, category: category)
        fbLogger = crashlytics
        mpLogger = MPLoggerAdapter(enabled: mpEnabled)
    }
    nonisolated public func log(_ log: String) {
        #if DEBUG
        osLogger.log("\(log, privacy: .public)")
        #else
        osLogger.log("\(log)")
        #endif
        fbLogger.log(log)
        mpLogger.log(log)
    }
    nonisolated public func error(_ error: Error) {
        #if DEBUG
        osLogger.error("\(error.description, privacy: .public)")
        #else
        osLogger.error("\(error.description)")
        #endif
        let callStack = createCallStackSymbols()
        fbLogger.record(error: error, userInfo: callStack)
        mpLogger.error(error, userInfo: callStack)
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
