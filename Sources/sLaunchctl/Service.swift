import Foundation


extension launchctl {
    public struct Service {
        public struct Info {
            public enum Status {
                /// Last exit status.
                case exitCode(Int)
                
                /// Signal number killed the job.
                case signal(Int32)
            }
            
            public let pid: pid_t?
            public let status: Status
        }
        
        public var name: String
        public var domainTarget: DomainTarget
        public var serviceTarget: String { "\(domainTarget)/\(name)" }
        
        public init(name: String, domainTarget: DomainTarget) {
            self.name = name
            self.domainTarget = domainTarget
        }
        
        public func bootout(_ serviceName: String) throws {
            try runLaunchctl(["bootout", serviceTarget])
        }
        
        public func enable(_ serviceName: String) throws {
            try runLaunchctl(["enable", serviceTarget])
        }
        
        public func disable(_ serviceName: String) throws {
            try runLaunchctl(["disable", serviceTarget])
        }
        
        /// Force a service to start.
        /// - Parameters:
        ///     - kill: 'true' will kill then restart existing instances.
        public func kickstart(kill: Bool) throws {
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
        
        /// Dumps the service's definition, properties & metadata.
        public func print() throws -> String {
            try runLaunchctl(["print", serviceTarget])
        }
        
        /// Dumps the service's state.
        public func info() throws -> Info {
            fatalError()
        }
    }
}
