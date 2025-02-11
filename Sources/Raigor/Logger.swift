import FirebaseCrashlytics
import Foundation
import os
import RegexBuilder
import SwiftUI

public protocol Logger {
    func log(_ log: String)
    func error(_ error: Error)
}

@propertyWrapper public struct AppLogger: DynamicProperty {
    public var wrappedValue: DefaultLogger
    
    public init() {
        self.wrappedValue = DefaultLogger()
    }
}

public actor DefaultLogger: Logger {
    private let osLogger: os.Logger
    init(
        bundle: Bundle = .main,
        fallbackSubsystem: String = "AppLogger",
        category: String = "Application"
    ) {
        let subsystem = bundle.bundleIdentifier ?? fallbackSubsystem
        osLogger = os.Logger(subsystem: subsystem, category: category)
    }
    nonisolated public func log(_ log: String) {
        osLogger.log("\(log)")
        Crashlytics.crashlytics().log(log) // stored as a log in an issue
    }
    nonisolated public func error(_ error: Error) {
        osLogger.error("\(error.description)")
        Crashlytics.crashlytics().record(error: error, userInfo: createUserInfo()) // stored as a non-fatal issue
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
