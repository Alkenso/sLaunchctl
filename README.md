# sLaunchctl - Swift API to manage daemons and user-agents

Developing for macOS often assumes interaction with root daemons and user agents. <br>
Unfortunately, Apple does not provide any actual API. (Existing SMJobXxx is deprecated)

sLaunchctl fills this gap providing convenient API that wraps up launchctl tool.

### Library family
You can also find Swift libraries for macOS / *OS development
- [SwiftConvenience](https://github.com/Alkenso/SwiftConvenience): Swift common extensions and utilities used in everyday development
- [sXPC](https://github.com/Alkenso/sXPC): Swift type-safe wrapper around NSXPCConnection and proxy object
- [sMock](https://github.com/Alkenso/sMock): Swift unit-test mocking framework similar to gtest/gmock

## Examples

#### Bootstrap
```
try launchctl.system.bootstrap(URL(fileURLWithPath: "/path/to/com.my.daemon.plist"))
try launchctl.gui().bootstrap(URL(fileURLWithPath: "/path/to/com.my.user_agent.plist"))
```

#### Bootout daemon
```
try launchctl.system.bootout(URL(fileURLWithPath: "/path/to/com.my.daemon.plist"))
try launchctl.gui().bootout(URL(fileURLWithPath: "/path/to/com.my.user_agent.plist"))
```

#### List all daemons
```
let rootDaemons = try launchctl.system.list()
let user505Agents = try launchctl.gui(505).list()
```

#### Rest functionas is inside sLaunchctl!
