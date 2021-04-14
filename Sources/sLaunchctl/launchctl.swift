import Foundation


public extension launchctl {
    static var system: launchctl { .init(domainTarget: .system) }
    static func gui(_ uid: uid_t = getuid()) -> launchctl { .init(domainTarget: .gui(uid)) }
}

public struct launchctl {
    public let domainTarget: DomainTarget
    
    public init(domainTarget: DomainTarget) {
        self.domainTarget = domainTarget
    }
    
    @discardableResult
    public func bootstrap(_ file: URL) throws -> Service {
        try runLaunchctl(["bootstrap", domainTarget.description, file.path])
        guard let name = NSDictionary(contentsOf: file)?
                .object(forKey: LAUNCH_JOBKEY_LABEL) as? String
        else {
            throw NSError(launchctlExitCode: EINVAL, stderr: "Provided file does not contain service label.")
        }
        return Service(name: name, domainTarget: domainTarget)
    }
    
    public func bootout(_ file: URL) throws {
        try runLaunchctl(["bootout", domainTarget.description, file.path])
    }
    
    /// Lists all services loaded into launchd for the current domain target.
    public func list() throws -> [Service] {
        let output = try runLaunchctl(["print", "system"])
        
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

public extension launchctl {
    enum DomainTarget {
        case system
        case gui(uid_t)
        case pid(pid_t)
        case user(uid_t)
        
// Commented due to future support
//        case login(au_asid_t)
//        case session(au_asid_t)
    }
}

extension launchctl.DomainTarget: CustomStringConvertible {
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
        }
    }
}
