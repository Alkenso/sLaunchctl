import Foundation


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
        
        /// Dumps the service's definition, properties & metadata.
        public func print() throws -> String {
            try runLaunchctl(["print", serviceTarget])
        }
    }
}
