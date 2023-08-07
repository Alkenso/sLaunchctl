import XCTest

extension XCTestCase {
    internal func checkLiveTestingAllowed() throws {
        try XCTSkipIf(true, "Live testing with real `launchctl` output is disabled by default")
    }
}
