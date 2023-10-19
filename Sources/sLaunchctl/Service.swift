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
import SpellbookFoundation

extension Launchctl {
    public struct Service {
        /// Service name
        public var name: String
        
        /// Service domain target.
        public var domainTarget: DomainTarget
        
        /// Service target (consists of domain and name).
        public var serviceTarget: String { "\(domainTarget)/\(name)" }
        
        public init(name: String, domainTarget: DomainTarget) {
            self.name = name
            self.domainTarget = domainTarget
        }
        
        /// Unloads the service.
        public func bootout() throws {
            try runLaunchctl(["bootout", serviceTarget])
        }
        
        /// Enables the service.
        public func enable() throws {
            try runLaunchctl(["enable", serviceTarget])
        }
        
        /// Disables the service.
        public func disable() throws {
            try runLaunchctl(["disable", serviceTarget])
        }
        
        /// Force a service to start.
        /// - Parameters:
        ///     - kill: 'true' will kill existing instances before starting.
        public func kickstart(kill: Bool = false) throws {
            var args = ["kickstart"]
            if kill {
                args.append("-k")
            }
            args.append(serviceTarget)
            try runLaunchctl(args)
        }
        
        /// Sends a signal to a service's process.
        public func kill(signum: Int32) throws {
            try runLaunchctl(["kill", String(signum), serviceTarget])
        }
        
        /// Dumps the service's definition, properties & metadata in structured way.
        public func info() throws -> ServiceInfo {
            let output = try print()
            do {
                return try OutputParser(string: output).serviceInfo()
            } catch {
                throw NSError(
                    launchctlExitCode: 109,
                    stderr: "Unsupported description of \(self).",
                    underlyingError: error
                )
            }
        }
        
        /// Dumps the service's definition, properties & metadata.
        public func print() throws -> String {
            try runLaunchctl(["print", serviceTarget])
        }
    }
}

extension Launchctl {
    public struct ServiceInfo: Equatable, Codable {
        public var pid: pid_t?
        public var daemon: DaemonInfo?
        public var loginItem: LoginItemInfo?
        public var endpoints: [String]?
        public var environment: Environment
        public var lastExitReason: ExitReason?
        
        public init(
            pid: pid_t?,
            daemon: DaemonInfo?,
            loginItem: LoginItemInfo?,
            endpoints: [String]?,
            environment: Environment,
            lastExitReason: ExitReason?
        ) {
            self.pid = pid
            self.daemon = daemon
            self.loginItem = loginItem
            self.endpoints = endpoints
            self.environment = environment
            self.lastExitReason = lastExitReason
        }
    }
    
    public enum ExitReason: Equatable, Codable {
        case signal(Int32)
        case exitCode(Int32)
    }
    
    public struct DaemonInfo: Equatable, Codable {
        public var plistPath: String
        public var program: String
        public var arguments: [String]?
        public var bundleID: String?
        
        public init(
            plistPath: String,
            program: String,
            arguments: [String]?,
            bundleID: String?
        ) {
            self.plistPath = plistPath
            self.program = program
            self.arguments = arguments
            self.bundleID = bundleID
        }
    }
    
    public struct LoginItemInfo: Equatable, Codable {
        public var identifier: String
        public var parentIdentifier: String
        
        public init(identifier: String, parentIdentifier: String) {
            self.identifier = identifier
            self.parentIdentifier = parentIdentifier
        }
    }
    
    public struct Environment: Equatable, Codable {
        public var generic: [String: String]?
        public var `default`: [String: String]?
        public var inherited: [String: String]?
        
        public init(
            generic: [String : String]? = nil,
            `default`: [String: String]? = nil,
            inherited: [String : String]? = nil
        ) {
            self.generic = generic
            self.default = `default`
            self.inherited = inherited
        }
    }
}

extension Launchctl.Service: CustomStringConvertible {
    public var description: String { serviceTarget }
}

extension OutputParser {
    internal func serviceInfo() throws -> Launchctl.ServiceInfo {
        let value = Launchctl.ServiceInfo(
            pid: (try? string(forKey: "pid")).flatMap(pid_t.init),
            daemon: daemonInfo(),
            loginItem: loginItemInfo(),
            endpoints: try? Array(OutputParser(string: container(forKey: "endpoints")).containers().keys),
            environment: environment(),
            lastExitReason: exitReason()
        )
        
        guard value.daemon != nil || value.loginItem != nil else {
            throw NSError(launchctlExitCode: 109, stderr: "Service information has unsupported format.")
        }
        
        return value
    }
    
    fileprivate func exitReason() -> Launchctl.ExitReason? {
        if let signal = (try? value(pattern: "last terminating signal = .*: (.*)", groupIdx: 1)).flatMap(Int32.init) {
            return .signal(signal)
        } else if let code = (try? string(forKey: "last exit code")).flatMap(Int32.init) {
            return .exitCode(code)
        } else {
            return nil
        }
    }
    
    fileprivate func daemonInfo() -> Launchctl.DaemonInfo? {
        do {
            return .init(
                plistPath: try string(forKey: "path"),
                program: try string(forKey: "program"),
                arguments: try? stringArray(forKey: "arguments"),
                bundleID: try? string(forKey: "bundle id")
            )
        } catch {
            return nil
        }
    }
    
    fileprivate func loginItemInfo() -> Launchctl.LoginItemInfo? {
        do {
            return .init(
                identifier: try value(pattern: "program identifier = (.*?)( |$)", groupIdx: 1),
                parentIdentifier: try string(forKey: "parent bundle identifier")
            )
        } catch {
            return nil
        }
    }
    
    fileprivate func environment() -> Launchctl.Environment {
        .init(
            generic: try? stringDictionary(forKey: "environment"),
            default: try? stringDictionary(forKey: "default environment"),
            inherited: try? stringDictionary(forKey: "inherited environment")
        )
    }
}
