@testable import sLaunchctl

import SpellbookFoundation
import XCTest

class ServiceParsingTests: XCTestCase {
    func test_daemon() throws {
        let output = """
        system/com.apple.akd = {
            active count = 7
            path = /System/Library/LaunchDaemons/com.apple.akd.plist
            type = LaunchDaemon
            state = running

            program = /System/Library/PrivateFrameworks/AuthKit.framework/Versions/A/Support/akd
            arguments = {
                /System/Library/PrivateFrameworks/AuthKit.framework/Versions/A/Support/akd
            }

            default environment = {
                PATH => /usr/bin:/bin:/usr/sbin:/sbin
            }

            environment = {
                MallocSpaceEfficient => 1
                XPC_SERVICE_NAME => com.apple.akd
            }

            domain = system
            minimum runtime = 10
            base minimum runtime = 10
            exit timeout = 5
            runs = 1
            pid = 928
            immediate reason = ipc (mach)
            forks = 0
            execs = 1
            initialized = 1
            trampolined = 1
            started suspended = 0
            proxy started suspended = 0
            last exit code = (never exited)

            endpoints = {
                "com.apple.ak.auth.xpc" = {
                    port = 0x3a777
                    active = 1
                    managed = 1
                    reset = 0
                    hide = 0
                    watching = 0
                }
                "com.apple.ak.anisette.xpc" = {
                    port = 0x39003
                    active = 1
                    managed = 1
                    reset = 0
                    hide = 0
                    watching = 0
                }
            }

            dynamic endpoints = {
                "com.apple.ak.aps" = {
                    port = 0x30d33
                    active = 1
                    managed = 0
                    reset = 0
                    hide = 0
                    watching = 0
                }
            }

            event channels = {
                "com.apple.rapport.matching" = {
                    port = 0x2f103
                    active = 1
                    managed = 1
                    reset = 0
                    hide = 0
                    watching = 0
                }
                "com.apple.notifyd.matching" = {
                    port = 0x38d03
                    active = 1
                    managed = 1
                    reset = 0
                    hide = 0
                    watching = 0
                }
                "com.apple.xpc.activity" = {
                    port = 0x2f003
                    active = 1
                    managed = 1
                    reset = 0
                    hide = 0
                    watching = 0
                }
            }

            spawn type = adaptive (6)
            jetsam priority = 40
            jetsam memory limit (active, soft) = 50 MB
            jetsam memory limit (inactive, soft) = 50 MB
            jetsamproperties category = daemon
            jetsam thread limit = 32
            cpumon = default
            job state = running
            probabilistic guard malloc policy = {
                activation rate = 1/1000
                sample rate = 1/0
            }

            properties = supports transactions | supports pressured exit | inferred program | system service | exponential throttling
        }
        """
        
        let info = try OutputParser(string: output).serviceInfo()
        let daemon = try info.daemon.get(name: "daemon")
        XCTAssertEqual(info.pid, 928)
        XCTAssertEqual(daemon, .init(
            plistPath: "/System/Library/LaunchDaemons/com.apple.akd.plist",
            program: "/System/Library/PrivateFrameworks/AuthKit.framework/Versions/A/Support/akd",
            arguments: ["/System/Library/PrivateFrameworks/AuthKit.framework/Versions/A/Support/akd"],
            bundleID: nil
        ))
        XCTAssertEqual(info.endpoints.flatMap(Set.init), [
            "com.apple.ak.auth.xpc",
            "com.apple.ak.anisette.xpc",
        ])
        XCTAssertEqual(info.environment, .init(
            generic: [
                "MallocSpaceEfficient": "1",
                "XPC_SERVICE_NAME": "com.apple.akd",
            ],
            default: ["PATH": "/usr/bin:/bin:/usr/sbin:/sbin"],
            inherited: nil
        ))
        XCTAssertEqual(info.lastExitReason, nil)
    }
    
    func test_loginItem() throws {
        let output = """
        gui/501/com.vendor.helper = {
            active count = 0
            path = (submitted by smd.500)
            type = Submitted
            state = not running

            program identifier = com.vendor.helper (mode: 1)
            parent bundle identifier = com.vendor.vendor
            parent bundle version = 93002
            BTM uuid = 2149970E-6C68-4C98-8D3A-EBA52AC7B12F
            inherited environment = {
                SSH_AUTH_SOCK => /private/tmp/com.apple.launchd.jAKz5dz9eY/Listeners
            }

            default environment = {
                PATH => /usr/bin:/bin:/usr/sbin:/sbin
            }

            environment = {
                XPC_SERVICE_NAME => com.vendor.helper
            }

            domain = gui/501 [100015]
            asid = 100015
            minimum runtime = 10
            exit timeout = 5
            runs = 1
            last exit code = 0

            semaphores = {
                successful exit => 0
            }

            endpoints = {
                "com.vendor.helper" = {
                    port = 0x9a403
                    active = 0
                    managed = 1
                    reset = 0
                    hide = 0
                    watching = 1
                }
            }

            spawn type = interactive (4)
            jetsam priority = 40
            jetsam memory limit (active) = (unlimited)
            jetsam memory limit (inactive) = (unlimited)
            jetsamproperties category = daemon
            submitted job. ignore execute allowed
            jetsam thread limit = 32
            cpumon = default
            job state = exited
            probabilistic guard malloc policy = {
                activation rate = 1/1000
                sample rate = 1/0
            }

            properties = supports transactions | resolve program | has LWCR
        }
        """
        
        let info = try OutputParser(string: output).serviceInfo()
        let loginItem = try info.loginItem.get(name: "loginItem")
        XCTAssertEqual(info.pid, nil)
        XCTAssertEqual(loginItem, .init(
            identifier: "com.vendor.helper",
            parentIdentifier: "com.vendor.vendor"
        ))
        XCTAssertEqual(info.endpoints.flatMap(Set.init), [
            "com.vendor.helper",
        ])
        XCTAssertEqual(info.environment, .init(
            generic: ["XPC_SERVICE_NAME": "com.vendor.helper"],
            default: ["PATH": "/usr/bin:/bin:/usr/sbin:/sbin"],
            inherited: ["SSH_AUTH_SOCK": "/private/tmp/com.apple.launchd.jAKz5dz9eY/Listeners"]
        ))
        XCTAssertEqual(info.lastExitReason, .exitCode(0))
    }
    
    func test_live() throws {
        try checkLiveTestingAllowed()
        
        let daemons = try Launchctl.system.list()
        try daemons.forEach { _ = try $0.info() }

        let agents = try Launchctl.gui().get(name: "current session agents").list()
        try agents.forEach { _ = try $0.info() }
    }
}
