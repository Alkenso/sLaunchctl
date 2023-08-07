//  MIT License
//
//  Copyright (c) 2022 Alkenso (Vladimir Vashurkin)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation

extension NSError {
    internal convenience init(launchctlExitCode: Int32, stderr: String, underlyingError: Error? = nil) {
        var userInfo: [String: Any] = [
            NSDebugDescriptionErrorKey: Self.xpc_strerr(launchctlExitCode),
            "stderr": stderr,
        ]
        if let underlyingError {
            userInfo[NSUnderlyingErrorKey] = underlyingError
        }
        
        self.init(domain: Launchctl.errorDomain, code: Int(launchctlExitCode), userInfo: userInfo)
    }
    
    private static func xpc_strerr(_ code: Int32) -> String {
        switch code {
        case 0..<107:
            return String(cString: strerror(code))
        case 107:
            return "Malformed bundle"
        case 108:
            return "Invalid path"
        case 109:
            return "Invalid property list"
        case 110:
            return "Invalid or missing service identifier"
        case 111:
            return "Invalid or missing Program/ProgramArguments"
        case 112:
            return "Could not find specified domain"
        case 113:
            return "Could not find specified service"
        case 114:
            return "The specified username does not exist"
        case 115:
            return "The specified group does not exist"
        case 116:
            return "Routine not yet implemented"
        case 117:
            return "(n/a)"
        case 118:
            return "Bad response from server"
        case 119:
            return "Service is disabled"
        case 120:
            return "Bad subsystem destination for request"
        case 121:
            return "Path not searched for services"
        case 122:
            return "Path had bad ownership/permissions"
        case 123:
            return "Path is whitelisted for domain"
        case 124:
            return "Domain is tearing down"
        case 125:
            return "Domain does not support specified action"
        case 126:
            return "Request type is no longer supported"
        case 127:
            return "The specified service did not ship with the operating system"
        case 128:
            return "The specified path is not a bundle"
        case 129:
            return "The service was superseded by a later later version"
        case 130:
            return "The system encountered a condition where behavior was undefined"
        case 131:
            return "Out of order requests"
        case 132:
            return "Request for stale data"
        case 133:
            return "Multiple errors were returned; see stderr"
        case 134:
            return "Service cannot load in requested session"
        case 135:
            return "Process is not managed"
        case 136:
            return "Action not allowed on singleton service"
        case 137:
            return "Service does not support the specified action"
        case 138:
            return "Service cannot be loaded on this hardware"
        case 139:
            return "Service cannot presently execute"
        case 140:
            return "Service name is reserved or invalid"
        case 141:
            return "Reentrancy avoided"
        case 142:
            return "Operation only supported on development"
        case 143:
            return "Requested entry was cached"
        case 144:
            return "Requestor lacks required entitlement"
        case 145:
            return "Endpoint is hidden"
        case 146:
            return "Domain is in on-demand-only mode"
        case 147:
            return "The specified service did not ship in the requestor"
        case 148:
            return "The specified service path was not in the service cache"
        case 149:
            return "Could not find a bundle of the given identifier through LaunchServices"
        case 150:
            return "Operation not permitted while System Integrity Protection is engaged"
        case 151:
            return "A complete hack"
        case 152:
            return "Service cannot load in current boot environment"
        case 153:
            return "Completely unexpected error"
        case 154:
            return "Requestor is not a platform binary"
        case 155:
            return "Refusing to execute/trust quarantined program/file"
        case 156:
            return "Domain creation with that UID is not allowed anymore"
        case 157:
            return "System service is not in system service whitelist"
        case 158:
            return "Service cannot be loaded on current os variant"
        case 159:
            return "Unknown error"
        default:
            return "unknown error code"
        }
    }
}
