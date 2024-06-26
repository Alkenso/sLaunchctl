The package now is part of [SwiftSpellbook_macOS](https://github.com/Alkenso/SwiftSpellbook_macOS)

# sLaunchctl - Swift API to manage daemons and user-agents

Developing for macOS often assumes interaction with root daemons and user agents. <br>
Unfortunately, Apple does not provide any actual API. (Existing SMJobXxx is deprecated)

sLaunchctl fills this gap providing convenient API that wraps up launchctl tool.

Read the article dedicated to the package: [sLaunchctl — Swift API to manage Daemons and Agents](https://medium.com/@alkenso/slaunchctl-swift-api-to-manage-daemons-and-agents-eea357f04782)

### Library family
You can also find Swift libraries for macOS / *OS development
- [SwiftSpellbook](https://github.com/Alkenso/SwiftSpellbook): Swift common extensions and utilities used in everyday development
- [sXPC](https://github.com/Alkenso/sXPC): Swift type-safe wrapper around NSXPCConnection and proxy object
- [sMock](https://github.com/Alkenso/sMock): Swift unit-test mocking framework similar to gtest/gmock
- [sEndpontSecurity](https://github.com/Alkenso/sEndpointSecurity): Swift wrapper around EndpointSecurity.framework

## Examples

#### Bootstrap
```
try Launchctl.system.bootstrap(URL(fileURLWithPath: "/path/to/com.my.daemon.plist"))
try Launchctl.gui().bootstrap(URL(fileURLWithPath: "/path/to/com.my.user_agent.plist"))
```

#### Bootout daemon
```
try Launchctl.system.bootout(URL(fileURLWithPath: "/path/to/com.my.daemon.plist"))
try Launchctl.gui().bootout(URL(fileURLWithPath: "/path/to/com.my.user_agent.plist"))
```

#### List all daemons
```
let rootDaemons = try Launchctl.system.list()
let user505Agents = try Launchctl.gui(505).list()
```

#### Find many more functional inside sLaunchctl!
