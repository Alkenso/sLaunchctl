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
