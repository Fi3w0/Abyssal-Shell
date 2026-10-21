pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import "kit"

Item {
    id: scene
    readonly property var t: Theme.current

    component Tool: Controls.Button {
        id: tool
        property string glyph: ""
        property bool destructive: false
        flat: false
        readonly property bool face: !flat || hovered || checked || down || activeFocus
        implicitWidth: 32
        implicitHeight: 30
        padding: 7
        hoverEnabled: true
        focusPolicy: Qt.StrongFocus
        Accessible.name: text || glyph
        background: Rectangle {
            radius: 6
            color: !tool.face ? "transparent" : tool.down ? scene.t.inset : tool.checked ? scene.t.selected : tool.hovered ? scene.t.hover : scene.t.control
            border.width: tool.face ? 1 : 0
            border.color: tool.activeFocus ? scene.t.accent : tool.checked ? scene.t.highlight : scene.t.controlEdge
            Rectangle {
                visible: tool.face
                x: 2
                y: 1
                width: parent.width - 4
                height: 1
                radius: 1
                color: scene.t.highlight
                opacity: tool.down ? 0 : 0.3
            }
        }
        contentItem: RowLayout {
            spacing: 7
            Glyph {
                visible: tool.glyph !== ""
                name: tool.glyph
                implicitWidth: 15
                implicitHeight: 15
                tint: tool.destructive ? scene.t.danger : tool.checked ? scene.t.accent : scene.t.text
                Layout.alignment: Qt.AlignHCenter
            }
            Label {
                visible: tool.text !== ""
                text: tool.text
                color: tool.destructive ? scene.t.danger : scene.t.text
                font.pixelSize: 12
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    component Header: Item {
        id: header
        property string title: ""
        property string glyph: ""
        property string hint: ""
        signal dismissed
        height: 34
        Rectangle {
            anchors.fill: parent
            radius: 5
            color: scene.t.title
        }
        Glyph {
            x: 10
            anchors.verticalCenter: parent.verticalCenter
            name: header.glyph
            implicitWidth: 15
            implicitHeight: 15
            tint: scene.t.accent
        }
        Label {
            x: 34
            anchors.verticalCenter: parent.verticalCenter
            text: header.title
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }
        Label {
            anchors {
                right: close.left
                rightMargin: 12
                verticalCenter: parent.verticalCenter
            }
            text: header.hint
            font.family: "JetBrains Mono"
            font.pixelSize: 10
            color: scene.t.muted
        }
        Tool {
            id: close
            anchors {
                right: parent.right
                rightMargin: 5
                verticalCenter: parent.verticalCenter
            }
            glyph: "x"
            implicitWidth: 24
            implicitHeight: 23
            Accessible.name: "Close " + header.title
            onClicked: header.dismissed()
        }
    }

    component Connection: Controls.Button {
        id: connection
        property string glyph: "wifi"
        property string detail: ""
        implicitHeight: 54
        padding: 7
        checkable: true
        hoverEnabled: true
        focusPolicy: Qt.StrongFocus
        background: Rectangle {
            radius: 7
            color: connection.hovered ? scene.t.raised : "transparent"
            border.width: connection.activeFocus ? 1 : 0
            border.color: scene.t.accent
        }
        contentItem: RowLayout {
            spacing: 11
            Rectangle {
                implicitWidth: 30
                implicitHeight: 30
                radius: 8
                color: connection.checked ? scene.t.selected : scene.t.inset
                border.width: 1
                border.color: connection.checked ? scene.t.controlEdge : scene.t.title
                Glyph {
                    anchors.centerIn: parent
                    name: connection.glyph
                    implicitWidth: 17
                    implicitHeight: 17
                    tint: connection.checked ? scene.t.accent : scene.t.muted
                }
            }
            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                Label {
                    text: connection.text
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }
                Label {
                    text: connection.detail
                    font.pixelSize: 11
                    color: scene.t.muted
                    Layout.fillWidth: true
                }
            }
            Rectangle {
                implicitWidth: 29
                implicitHeight: 16
                radius: 8
                color: connection.checked ? scene.t.accent : scene.t.inset
                border.width: connection.checked ? 0 : 1
                border.color: scene.t.controlEdge
                Rectangle {
                    x: connection.checked ? 16 : 3
                    y: 3
                    width: 10
                    height: 10
                    radius: 5
                    color: connection.checked ? scene.t.ink : scene.t.muted
                    Behavior on x {
                        NumberAnimation {
                            duration: 110
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }

    component AudioChannel: Item {
        id: channel
        property string title: ""
        property string glyph: "volume-high"
        property real level: 0
        property bool muted: false
        signal muteClicked
        signal adjusted(real level)
        height: 58
        Tool {
            x: 0
            y: 15
            glyph: channel.glyph
            implicitWidth: 32
            implicitHeight: 32
            checked: channel.muted
            Accessible.name: "Mute " + channel.title
            onClicked: channel.muteClicked()
        }
        Label {
            x: 44
            y: 0
            text: channel.title
            font.pixelSize: 12
        }
        Label {
            anchors {
                right: parent.right
                top: parent.top
            }
            text: channel.muted ? "Muted" : Math.round(channel.level) + "%"
            font.family: "JetBrains Mono"
            font.pixelSize: 11
            color: scene.t.muted
        }
        Controls.Slider {
            id: slider
            x: 43
            y: 22
            width: parent.width - 43
            height: 27
            from: 0
            to: 100
            stepSize: 1
            value: channel.muted ? 0 : channel.level
            focusPolicy: Qt.StrongFocus
            Accessible.name: channel.title + " volume"
            onMoved: channel.adjusted(value)
            background: Rectangle {
                x: slider.leftPadding
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                width: slider.availableWidth
                height: 8
                radius: 4
                color: scene.t.inset
                border.width: 1
                border.color: scene.t.controlEdge
                Rectangle {
                    x: 1
                    y: 1
                    width: Math.max(0, (parent.width - 2) * slider.visualPosition)
                    height: 6
                    radius: 3
                    color: scene.t.accent
                    opacity: 0.7
                }
            }
            handle: Rectangle {
                x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                width: 10
                height: 17
                radius: 4
                color: scene.t.text
                border.width: 1
                border.color: slider.activeFocus ? scene.t.accent : scene.t.highlight
            }
        }
    }

    component MenuAction: Controls.Button {
        id: action
        property string glyph: "app"
        property bool destructive: false
        implicitHeight: 34
        padding: 9
        hoverEnabled: true
        focusPolicy: Qt.StrongFocus
        background: Rectangle {
            color: action.hovered || action.activeFocus ? scene.t.selected : "transparent"
            radius: 5
            border.width: action.activeFocus ? 1 : 0
            border.color: scene.t.accent
        }
        contentItem: RowLayout {
            spacing: 12
            Glyph {
                name: action.glyph
                implicitWidth: 15
                implicitHeight: 15
                tint: action.destructive ? scene.t.danger : scene.t.muted
            }
            Label {
                text: action.text
                font.pixelSize: 12
                color: action.destructive ? scene.t.danger : scene.t.text
                Layout.fillWidth: true
            }
        }
    }

    // The panel's frame and individual controls have different material roles.
    Frame {
        x: 20
        y: 20
        width: 76
        height: 810
        cut: 12
        rounding: 7
        Tool {
            x: 15
            y: 22
            implicitWidth: 46
            implicitHeight: 42
            glyph: "logo"
            flat: true
            checked: Sample.launcher
            Accessible.name: "Show launcher"
            onClicked: Sample.launcher = !Sample.launcher
        }
        Column {
            x: 12
            y: 100
            width: 52
            spacing: 10
            Repeater {
                model: 4
                Tool {
                    required property int index
                    width: 52
                    height: 36
                    text: "0" + (index + 1)
                    flat: true
                    checked: Sample.workspace === index
                    onClicked: Sample.workspace = index
                }
            }
        }
        Rectangle {
            x: 16
            y: 302
            width: 44
            height: 1
            color: scene.t.line
        }
        Column {
            x: 13
            y: 330
            width: 50
            spacing: 12
            Repeater {
                model: Sample.apps
                Controls.Button {
                    id: pinnedApp
                    required property var modelData
                    required property int index
                    width: 50
                    height: 45
                    padding: 8
                    hoverEnabled: true
                    Accessible.name: "Preview " + modelData.name
                    background: Rectangle {
                        radius: 8
                        color: pinnedApp.hovered ? scene.t.raised : "transparent"
                        border.width: pinnedApp.activeFocus ? 1 : 0
                        border.color: scene.t.accent
                    }
                    contentItem: Image {
                        source: pinnedApp.modelData.image
                        sourceSize: Qt.size(72, 72)
                        fillMode: Image.PreserveAspectFit
                    }
                    onClicked: {
                        Sample.feedback = "Selected " + modelData.name + " · Preview only";
                        Sample.launcher = true;
                    }
                }
            }
        }
        Tool {
            x: 22
            y: 696
            glyph: "sliders"
            flat: true
            checked: Sample.controls
            Accessible.name: "Show session controls"
            onClicked: Sample.controls = !Sample.controls
        }
        Label {
            x: 22
            y: 750
            text: "22"
            font.family: "JetBrains Mono"
            font.pixelSize: 18
        }
        Label {
            x: 22
            y: 776
            text: "41"
            font.family: "JetBrains Mono"
            font.pixelSize: 18
            color: scene.t.muted
        }
    }

    Label {
        x: 146
        y: 36
        text: "abyssal"
        font.pixelSize: 18
        font.weight: Font.DemiBold
    }
    Label {
        x: 146
        y: 67
        text: "Workspace 0" + (Sample.workspace + 1) + "  ·  Firefox"
        font.family: "JetBrains Mono"
        font.pixelSize: 11
        color: scene.t.muted
    }
    Label {
        x: 1265
        y: 37
        text: "22:41"
        font.family: "JetBrains Mono"
        font.pixelSize: 22
    }
    Label {
        x: 1265
        y: 69
        text: "Wed 21 Oct"
        font.pixelSize: 11
        color: scene.t.muted
    }

    Frame {
        x: 210
        y: 176
        width: 650
        height: 420
        cut: 14
        rounding: 8
        visible: Sample.launcher
        Header {
            x: 13
            y: 11
            width: 624
            title: "Applications"
            glyph: "grid"
            hint: "Super + Space"
            onDismissed: Sample.launcher = false
        }
        Rectangle {
            x: 18
            y: 60
            width: 614
            height: 49
            radius: 8
            color: scene.t.inset
            border.width: 1
            border.color: launcherQuery.activeFocus ? scene.t.highlight : scene.t.line
            Glyph {
                x: 14
                y: 15
                name: "search"
                implicitWidth: 18
                implicitHeight: 18
                tint: scene.t.muted
            }
            Search {
                id: launcherQuery
                x: 39
                y: 0
                width: 565
                height: 49
                font.pixelSize: 18
                background: Item {}
            }
        }
        AppList {
            x: 18
            y: 126
            width: 614
            rowHeight: 54
            textSize: 15
            iconSize: 31
            icons: true
            numbers: false
            edgeMark: true
            onContextRequested: entry => Sample.menu = true
        }
        Rectangle {
            x: 24
            y: 373
            width: 602
            height: 1
            color: scene.t.line
        }
        Label {
            x: 29
            y: 389
            text: "↑↓ Select     Enter Open"
            font.family: "JetBrains Mono"
            font.pixelSize: 10
            color: scene.t.muted
        }
        Label {
            x: 452
            y: 389
            text: "Right-click for options"
            font.pixelSize: 10
            color: scene.t.muted
        }
    }

    Frame {
        x: 1000
        y: 112
        width: 370
        height: 552
        cut: 14
        rounding: 8
        visible: Sample.controls
        Header {
            x: 13
            y: 11
            width: 344
            title: "Session"
            glyph: "sliders"
            onDismissed: Sample.controls = false
        }
        Rectangle {
            x: 23
            y: 63
            width: 36
            height: 36
            radius: 10
            color: scene.t.selected
            border.width: 1
            border.color: scene.t.controlEdge
            Glyph {
                anchors.centerIn: parent
                name: "user"
                tint: scene.t.accent
                implicitWidth: 20
                implicitHeight: 20
            }
        }
        Label {
            x: 71
            y: 62
            text: "user"
            font.pixelSize: 15
            font.weight: Font.DemiBold
        }
        Label {
            x: 71
            y: 85
            text: "Desktop controls"
            font.pixelSize: 11
            color: scene.t.muted
        }
        Label {
            x: 24
            y: 122
            text: "Connections"
            font.pixelSize: 10
            color: scene.t.muted
        }
        Connection {
            x: 17
            y: 141
            width: 336
            text: "Wi-Fi"
            detail: Sample.wifi ? "Home network" : "Disconnected"
            glyph: Sample.wifi ? "wifi" : "wifi-off"
            checked: Sample.wifi
            onClicked: Sample.wifi = !Sample.wifi
        }
        Connection {
            x: 17
            y: 198
            width: 336
            text: "Bluetooth"
            detail: Sample.bluetooth ? "Headphones connected" : "Off"
            glyph: "bluetooth"
            checked: Sample.bluetooth
            onClicked: Sample.bluetooth = !Sample.bluetooth
        }
        Rectangle {
            x: 24
            y: 269
            width: 322
            height: 1
            color: scene.t.line
        }
        RowLayout {
            x: 24
            y: 286
            width: 322
            height: 31
            spacing: 10
            Tool {
                Layout.fillWidth: true
                glyph: Sample.quiet ? "bell-off" : "bell"
                text: "Quiet"
                checked: Sample.quiet
                Accessible.name: "Do not disturb"
                onClicked: Sample.quiet = !Sample.quiet
            }
            Tool {
                Layout.fillWidth: true
                glyph: "coffee"
                text: "Awake"
                checked: Sample.awake
                Accessible.name: "Keep awake"
                onClicked: Sample.awake = !Sample.awake
            }
        }
        AudioChannel {
            x: 24
            y: 343
            width: 322
            title: "Headphones"
            glyph: Sample.muted ? "volume-mute" : "volume-high"
            level: Sample.volume
            muted: Sample.muted
            onMuteClicked: Sample.muted = !Sample.muted
            onAdjusted: v => {
                Sample.volume = v;
                Sample.muted = false;
            }
        }
        AudioChannel {
            x: 24
            y: 419
            width: 322
            title: "Microphone"
            glyph: Sample.micMuted ? "mic-off" : "mic"
            level: Sample.microphone
            muted: Sample.micMuted
            onMuteClicked: Sample.micMuted = !Sample.micMuted
            onAdjusted: v => {
                Sample.microphone = v;
                Sample.micMuted = false;
            }
        }
        Rectangle {
            x: 24
            y: 490
            width: 322
            height: 1
            color: scene.t.line
        }
        RowLayout {
            x: 24
            y: 507
            width: 322
            height: 30
            spacing: 9
            Tool {
                Layout.fillWidth: true
                glyph: "lock"
                text: "Lock"
                onClicked: Sample.feedback = "Lock selected · Preview only"
            }
            Tool {
                Layout.fillWidth: true
                glyph: "moon"
                text: "Sleep"
                onClicked: Sample.feedback = "Sleep selected · Preview only"
            }
            Tool {
                Layout.fillWidth: true
                glyph: "power"
                text: "Power"
                destructive: true
                onClicked: Sample.feedback = "Power selected · Preview only"
            }
        }
    }

    Frame {
        x: 210
        y: 643
        width: 278
        height: 173
        cut: 11
        rounding: 7
        visible: Sample.menu
        Label {
            x: 20
            y: 14
            text: Sample.current ? Sample.current.name : "Application"
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: scene.t.muted
        }
        Rectangle {
            x: 14
            y: 39
            width: 250
            height: 1
            color: scene.t.line
        }
        Column {
            x: 8
            y: 47
            width: 262
            spacing: 2
            MenuAction {
                width: 262
                text: Sample.pinned ? "Unpin from panel" : "Pin to panel"
                glyph: Sample.pinned ? "minus" : "plus"
                onClicked: {
                    Sample.pinned = !Sample.pinned;
                    Sample.feedback = "Pin preference changed · Preview only";
                    Sample.menu = false;
                }
            }
            MenuAction {
                width: 262
                text: "New window"
                glyph: "app"
                onClicked: {
                    Sample.feedback = "New window selected · Preview only";
                    Sample.menu = false;
                }
            }
            MenuAction {
                width: 262
                text: "Close windows"
                glyph: "x"
                destructive: true
                onClicked: {
                    Sample.feedback = "Close windows selected · Preview only";
                    Sample.menu = false;
                }
            }
        }
    }

    Frame {
        x: 566
        y: 751
        width: 338
        height: 66
        cut: 11
        rounding: 7
        Dock {
            anchors {
                fill: parent
                margins: 4
            }
        }
    }

    Frame {
        x: 1000
        y: 705
        width: 370
        height: 111
        cut: 12
        rounding: 7
        visible: Sample.notification
        Rectangle {
            x: 19
            y: 28
            width: 32
            height: 32
            radius: 9
            color: scene.t.inset
            border.width: 1
            border.color: scene.t.controlEdge
            Glyph {
                anchors.centerIn: parent
                name: "bell"
                tint: scene.t.accent
                implicitWidth: 17
                implicitHeight: 17
            }
        }
        Label {
            x: 64
            y: 21
            text: "Screenshot"
            font.pixelSize: 10
            color: scene.t.muted
        }
        Label {
            x: 64
            y: 43
            text: "Screenshot saved"
            font.pixelSize: 15
            font.weight: Font.DemiBold
        }
        Label {
            x: 64
            y: 72
            text: "Pictures/Screenshots"
            font.pixelSize: 11
            color: scene.t.muted
        }
        Tool {
            x: 326
            y: 12
            glyph: "x"
            implicitWidth: 24
            implicitHeight: 24
            Accessible.name: "Dismiss sample notification"
            onClicked: Sample.notification = false
        }
    }
}
