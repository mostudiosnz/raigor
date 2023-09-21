import FirebaseCrashlytics
import Foundation
import os
import RegexBuilder

public protocol Logger {
    static var shared: Logger { get }
    func log(_ log: String)
    func error(_ error: Error)
}

public struct AppLogger: Logger {
    public static let shared: Logger = AppLogger()
    private let osLogger: os.Logger
    private let fbLogger: Crashlytics
    init(
        bundle: Bundle = .main,
        fallbackSubsystem: String = "AppLogger",
        category: String = "Application"
    ) {
        let subsystem = bundle.bundleIdentifier ?? fallbackSubsystem
        osLogger = os.Logger(subsystem: subsystem, category: category)
        fbLogger = Crashlytics.crashlytics()
    }
    public func log(_ log: String) {
        osLogger.log("\(log)")
        fbLogger.log(log) // stored as a log in an issue
    }
    public func error(_ error: Error) {
        osLogger.error("\(error.description)")
        fbLogger.record(error: error, userInfo: createUserInfo()) // stored as a non-fatal issue
    }
    func createUserInfo() -> [String: Any] {
        guard #available(iOS 16.0, *) else { return [:] }
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
