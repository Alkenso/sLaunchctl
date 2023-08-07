@testable import sLaunchctl

import XCTest

class LaunchctlParsingTests: XCTestCase {
    func test_services() throws {
        let output = """
        system = {
            type = system
            handle = 0
            active count = 742
            service count = 380
            active service count = 146
            maximum allowed shutdown time = 65 s
            service stats = {
                com.apple.launchd.service-stats-default (4096 records)
            }
            creator = launchd[1]
            creator euid = 0
            auxiliary bootstrapper = com.apple.xpc.smd (complete)
            security context = {
                uid unset
                asid = 0
            }

            bringup time = 107 ms
            death port = 0xa03
            subdomains = {
                pid/39576
                user/0
            }

            services = {
                       0      -     com.apple.lskdd
                     184      -     com.apple.runningboardd
                       0      -     com.apple.relatived
            }

            unmanaged processes = {
                com.apple.xpc.launchd.unmanaged.nsattributedstr.36189 = {
                    active count = 3
                    dynamic endpoints = {
                    }
                    pid-local endpoints = {
                        "com.apple.tsm.portname" = {
                            port = 0x1c91f
                            active = 1
                            managed = 0
                            reset = 0
                            hide = 0
                            watching = 0
                        }
                        "com.apple.axserver" = {
                            port = 0x6da4b
                            active = 1
                            managed = 0
                            reset = 0
                            hide = 0
                            watching = 0
                        }
                    }
                }
            }

            endpoints = {
                       0    M   D   com.apple.fpsd.arcadeservice
                 0x1090b    M   A   com.apple.VirtualDisplay
                   0xe03    M   A   com.apple.logd.admin
            }

            task-special ports = {
                      0x1c03 4       bootstrap  com.apple.xpc.launchd.domain.system
                      0x2203 9          access  com.apple.taskgated
            }

            disabled services = {
                "com.apple.CSCSupportd" => disabled
                "com.apple.ftpd" => disabled
                "com.apple.mdmclient.daemon.runatboot" => disabled
            }

            properties = uncorked | audit check done | bootcache hack
        }
        """
        
        let info = try OutputParser(string: output).services()
        XCTAssertEqual(Set(info), [
            "com.apple.lskdd",
            "com.apple.runningboardd",
            "com.apple.relatived",
        ])
    }
    
    func test_live() throws {
        try checkLiveTestingAllowed()
        
        let daemons = try Launchctl.system.list()
        XCTAssertFalse(daemons.isEmpty)
        
        let agents = try Launchctl.gui()?.list()
        XCTAssertFalse(agents?.isEmpty ?? true)
    }
}
