import XCTest

@testable import Raigor

final class LoggerTests: XCTestCase {
  func testMixpanelLoggingWithoutInitializedInstance() {
    let logger = MPLoggerAdapter(
      logEnabled: true,
      errorEnabled: true,
      mixpanelInstance: nil
    )

    logger.log("Test message")
    logger.error(NSError(domain: "RaigorTests", code: 1), userInfo: ["context": "test"])
  }
}
