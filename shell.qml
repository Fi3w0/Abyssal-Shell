//@ pragma UseQApplication

import QtQuick
import Quickshell
import "bar"
import "panels"
import "services"

// Abyssal Shell, for TideWM. Each monitor gets the bars its layout entry
// asks for, its own toasts, quick settings, volume popup, and the power
// menu and bar editor when opened there. The lock screen is a separate
// instance (lock/shell.qml).
ShellRoot {
    // Touch the services so they start with the shell, not on first use.
    readonly property var _services: [Tide, SystemInfo, Notifications, Shell, Audio]

    Variants {
        model: Quickshell.screens

        delegate: Scope {
            id: monitor
            required property var modelData

            Variants {
                model: BarLayout.barsFor(monitor.modelData.name)
                delegate: Bar {
                    required property var modelData
                    screen: monitor.modelData
                    config: modelData
                }
            }

            ToastStack { screen: monitor.modelData }
            Osd { screen: monitor.modelData }
            QuickSettings { screen: monitor.modelData }

            LazyLoader {
                active: Shell.editing
                EditPanel { screen: monitor.modelData }
            }

            LazyLoader {
                active: Shell.powerOn === monitor.modelData.name
                PowerMenu { screen: monitor.modelData }
            }
        }
    }

    // One inhibitor for the whole session, on the first screen.
    Caffeine {
        screen: Quickshell.screens[0]
        active: Shell.caffeine
    }
}
