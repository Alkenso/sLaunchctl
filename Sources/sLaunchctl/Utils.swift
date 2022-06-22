import SwiftConvenience

import Foundation
import SystemConfiguration


@discardableResult
func runLaunchctl(_ args: [String]) throws -> String {
    let (exitCode, stdout, stderr) = Process.launch(
        tool: URL(fileURLWithPath: "/bin/launchctl"),
        arguments: args
    )
    guard exitCode == 0 || exitCode == EINPROGRESS else {
        throw NSError(launchctlExitCode: exitCode, stderr: stderr)
    }
    
    return stdout
}

func loggedInUser() -> uid_t? {
    var uid: uid_t = 0
    var gid: gid_t = 0
    let found = SCDynamicStoreCopyConsoleUser(nil, &uid, &gid) != nil
    return found ? uid : nil
}

extension String {
    // supports one and only one capture group
    func launchctlFindValue(pattern: String) throws -> String {
        let regex = try NSRegularExpression(pattern: pattern)
        let nsString = self as NSString
        guard let result = regex.firstMatch(in: self, range: NSRange(location: 0, length: nsString.length)),
              result.numberOfRanges == 2
        else {
            throw CommonError.notFound(what: "regex group value", value: pattern, where: self)
        }
        
        return nsString.substring(with: result.range(at: 1)) as String
    }
    
    func launchctlFindValue(forKey key: String) throws -> String {
        try launchctlFindValue(pattern: "\(key) = (.*)")
    }
}
