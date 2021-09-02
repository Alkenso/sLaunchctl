import Foundation


public extension Launchctl {
    /// Launchctl instance for system domain target.
    static var system: Launchctl { .init(domainTarget: .system) }
    
    /// Launchctl instance for gui domain target.
    static func gui(_ uid: uid_t) -> Launchctl { .init(domainTarget: .gui(uid)) }
    
    /// Launchctl instance for gui domain target of currently logged in user.
    static func gui() -> Launchctl? { loggedInUser().flatMap(Launchctl.gui(_:)) }
}

public struct Launchctl {
    public let domainTarget: DomainTarget
    
    public init(domainTarget: DomainTarget) {
        self.domainTarget = domainTarget
    }
    
    /// Loads the specified service.
    @discardableResult
    public func bootstrap(plist: URL) throws -> Service {
        try runLaunchctl(["bootstrap", domainTarget.description, plist.path])
        guard let name = NSDictionary(contentsOf: plist)?
                .object(forKey: LAUNCH_JOBKEY_LABEL) as? String
        else {
            throw NSError(launchctlExitCode: EINVAL, stderr: "Provided file does not contain service label.")
        }
        return Service(name: name, domainTarget: domainTarget)
    }
    
    /// Unloads the specified service.
    public func bootout(plist: URL) throws {
        try runLaunchctl(["bootout", domainTarget.description, plist.path])
    }
    
    /// Unloads the specified service.
    public func bootout(label: String) throws {
        let serviceTarget = Service(name: label, domainTarget: domainTarget).serviceTarget
        try runLaunchctl(["bootout", serviceTarget])
    }
    
    /// Lists all services loaded into launchd for the current domain target.
    public func list() throws -> [Service] {
        let output = try runLaunchctl(["print", domainTarget.description])
        
        let regex = try NSRegularExpression(pattern: "(?:\n[\\s\t]*services = \\{)((?:\n.*?)*?)[\t\\s]*\\}")
        let nsString = output as NSString
        let results = regex.matches(
            in: output,
            range: NSRange(location: 0, length: nsString.length)
        )
        
        guard results.count == 1, results[0].numberOfRanges == 2 else {
            throw NSError(launchctlExitCode: ENOATTR, stderr: "No services dict found.")
        }
        
        let services = nsString.substring(with: results[0].range(at: 1))
        return services.components(separatedBy: .newlines)
            .map { $0.components(separatedBy: .whitespaces) }
            .compactMap(\.last)
            .filter { !$0.isEmpty }
            .map { Service(name: String($0), domainTarget: domainTarget) }
    }
    
    /// Prints the domain's metadata, including but not limited to all services in the domain.
    public func print() throws -> String {
        try runLaunchctl(["print", domainTarget.description])
    }
}

public extension Launchctl {
    enum DomainTarget {
        case system
        case gui(uid_t)
        
        // Rare use
        case pid(pid_t)
        case user(uid_t)
        case login(au_asid_t)
        case session(au_asid_t)
    }
}

extension Launchctl.DomainTarget: CustomStringConvertible {
    public var description: String {
        switch self {
        case .system:
            return "system"
        case .gui(let uid):
            return "gui/\(uid)"
        case .pid(let pid):
            return "pid/\(pid)"
        case .user(let uid):
            return "user/\(uid)"
        case .login(let asid):
            return "login/\(asid)"
        case .session(let asid):
            return "session/\(asid)"
        }
    }
}
