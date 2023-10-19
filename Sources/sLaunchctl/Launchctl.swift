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
    /// Launchctl instance for system domain target.
    public static var system: Launchctl { .init(domainTarget: .system) }
    
    /// Launchctl instance for gui domain target.
    public static func gui(_ uid: uid_t) -> Launchctl { .init(domainTarget: .gui(uid)) }
    
    /// Launchctl instance for gui domain target of currently logged in user.
    public static func gui() -> Launchctl? { UnixUser.currentSession.flatMap { .gui($0.uid) } }
}

extension Launchctl {
    public static let errorDomain = "LaunchctlErrorDomain"
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
        let output = try print()
        do {
            let names = try OutputParser(string: output).services()
            return names.map { Service(name: $0, domainTarget: domainTarget) }
        } catch {
            throw NSError(launchctlExitCode: ENOATTR, stderr: "No services dict found.", underlyingError: error)
        }
    }
    
    /// Prints the domain's metadata, including but not limited to all services in the domain.
    public func print() throws -> String {
        try runLaunchctl(["print", domainTarget.description])
    }
}

extension Launchctl {
    public enum DomainTarget {
        /// `system` domain target usually used by system-wide daemons, privileged helpers, system extensions.
        case system
        
        /// `gui` domain target usually used by per-user agents and login items.
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

extension OutputParser {
    internal func services() throws -> [String] {
        let lines = try stringArray(forKey: "services")
        return lines
            .map { $0.components(separatedBy: .whitespaces) }
            .compactMap(\.last)
            .filter { !$0.isEmpty }
    }
}
