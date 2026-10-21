//@ pragma UseQApplication

import QtQuick
import Quickshell
import "bar"
import "edit"
import "panels"
import "services"

// Abyssal Shell, for TideWM. Each monitor gets the panels its layout entry
// asks for (taskbar, top bar, dock: all the same Panel), its own toasts,
// quick settings, app launcher and volume popup, and the power menu and the
// edit-mode overlays when they are open there. The lock screen is a
// separate instance (lock/shell.qml).
ShellRoot {
    // Touch the services so they start with the shell, not on first use.
    readonly property var _services: [Tide, SystemInfo, Notifications, Shell, Audio, Wallpaper, Idle, Clipboard, Themes, Updates]

    Variants {
        model: Quickshell.screens

        delegate: Scope {
            id: monitor
            required property var modelData

            Variants {
                // Keep each edge's window when appearance or widgets change.
                model: PanelLayout.panelsFor(monitor.modelData.name).map(p => p.edge)
                delegate: Panel {
                    required property string modelData
                    screen: monitor.modelData
                    config: PanelLayout.panelsFor(monitor.modelData.name).find(p => p.edge === modelData)
                            || PanelLayout.normalise({ items: [] }, modelData)
                }
            }

            ToastStack { screen: monitor.modelData; output: monitor.modelData.name }
            Osd { screen: monitor.modelData; output: monitor.modelData.name }
            QuickSettings { screen: monitor.modelData }
            DetailPopup { screen: monitor.modelData }
            IdleBlank { screen: monitor.modelData }
            AppLauncher { screen: monitor.modelData; output: monitor.modelData.name }
            WallpaperPicker { screen: monitor.modelData; output: monitor.modelData.name }
            Welcome { screen: monitor.modelData }

            // Edit mode
            EditPill { screen: monitor.modelData; output: monitor.modelData.name }
            WidgetSidebar { screen: monitor.modelData; output: monitor.modelData.name }
            PositionOverlay { screen: monitor.modelData; output: monitor.modelData.name }

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
