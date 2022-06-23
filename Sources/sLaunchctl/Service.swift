import Foundation
import SwiftConvenience

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
        
        /// Dumps the service's definition, properties & metadata. in structured way.
        public func info() throws -> ServiceInfo {
            let raw = try print()
            return try ServiceInfo(
                pid: (try? raw.launchctlFindValue(forKey: "pid")).flatMap(pid_t.init),
                plistPath: raw.launchctlFindValue(forKey: "path"),
                program: raw.launchctlFindValue(forKey: "program"),
                bundleID: try? raw.launchctlFindValue(forKey: "bundle id"),
                lastExitReason: .init(raw: raw)
            )
        }
        
        /// Dumps the service's definition, properties & metadata.
        public func print() throws -> String {
            try runLaunchctl(["print", serviceTarget])
        }
    }
    
    public struct ServiceInfo: Equatable, Codable {
        public var pid: pid_t?
        public var plistPath: String
        public var program: String
        public var bundleID: String?
        public var lastExitReason: ExitReason?
    }
    
    public enum ExitReason: Equatable, Codable {
        case signal(Int32)
        case exitCode(Int32)
    }
}

private extension Launchctl.ExitReason {
    init?(raw: String) {
        if let signal = (try? raw.launchctlFindValue(pattern: "last terminating signal = .*: (.*)")).flatMap(Int32.init) {
            self = .signal(signal)
        } else if let code = (try? raw.launchctlFindValue(forKey: "last exit code")).flatMap(Int32.init) {
            self = .exitCode(code)
        } else {
            return nil
        }
    }
}
