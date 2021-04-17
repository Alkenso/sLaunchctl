import SwiftConvenience

import Foundation


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
