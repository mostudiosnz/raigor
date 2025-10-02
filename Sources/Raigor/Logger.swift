import FirebaseCrashlytics
import Foundation
import os
import RegexBuilder
import SwiftUI

public protocol Logger: Sendable {
    func log(_ log: String)
    func log_public(_ log: String)
    func error(_ error: Error)
    func error_public(_ error: Error)
}

@propertyWrapper public struct AppLogger: DynamicProperty {
    public var wrappedValue: DefaultLogger
    
    public init() {
        self.wrappedValue = DefaultLogger()
    }
}

extension Crashlytics: @unchecked @retroactive Sendable {}

/**
 Logs to both `os.Logger` and `Crashlytics`
 */
public actor DefaultLogger: Logger {
    private let osLogger: os.Logger
    private let fbLogger: Crashlytics
    public init(
        bundle: Bundle = .main,
        fallbackSubsystem: String = "AppLogger",
        category: String = "Application",
        crashlytics: Crashlytics = .crashlytics()
    ) {
        let subsystem = bundle.bundleIdentifier ?? fallbackSubsystem
        osLogger = os.Logger(subsystem: subsystem, category: category)
        fbLogger = crashlytics
    }
    nonisolated public func log(_ log: String) {
        osLogger.log("\(log)")
        fbLogger.log(log)
    }
    nonisolated public func log_public(_ log: String) {
        osLogger.log("\(log)")
        fbLogger.log(log)
    }
    nonisolated public func error(_ error: Error) {
        osLogger.error("\(error.description, privacy: .public)")
        fbLogger.record(error: error, userInfo: createUserInfo())
    }
    nonisolated public func error_public(_ error: any Error) {
        osLogger.error("\(error.description, privacy: .public)")
        fbLogger.record(error: error, userInfo: createUserInfo())
    }
    nonisolated func createUserInfo() -> [String: Any] {
        guard #available(iOS 16.0, macOS 13.0, *) else { return [:] }
        let regex = Regex {
            Capture({ OneOrMore(.digit) }, transform: { Int($0) ?? -1 })
            OneOrMore(.whitespace)
            Capture{ OneOrMore(.word) }
            OneOrMore(.whitespace)
            Capture{ OneOrMore(.anyNonNewline) }
        }
        return Thread.callStackSymbols.compactMap { try? regex.firstMatch(in: $0) }
            .reduce([:] as [String: Any], { dict, result in
                let key = "\(result.1) \(result.2)"
                let value = "\(result.3)"
                return dict.merging([key: value as Any], uniquingKeysWith: { $1 })
            })
    }
}

private extension Error {
    var description: String {
        (self as NSError).description
    }
}
