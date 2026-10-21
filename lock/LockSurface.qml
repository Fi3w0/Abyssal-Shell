import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io

// One monitor's lock screen: deep-sea backdrop with drifting glows, the
// time, and a password field. Self-contained (own palette copy) so the lock
// instance does not depend on the main shell's files.
Item {
    id: root

    required property var lockRoot

    // The main shell's active theme (services/Themes.qml writes it), read
    // once; Abyssal Tide when it is missing or broken.
    readonly property var theme: {
        try { return JSON.parse(themeFile.text()).colors || {} } catch (e) { return {} }
    }
    FileView {
        id: themeFile
        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/abyssal/theme.json"
        blockLoading: true
        printErrors: false
    }
    readonly property color crust:   theme.crust || "#080b17"
    readonly property color base:    theme.base || "#0c1020"
    readonly property color surface: theme.surface0 || "#161b2e"
    readonly property color overlay: theme.overlay || "#525c7e"
    readonly property color subtext: theme.subtext || "#9aa3c4"
    readonly property color text:    theme.text || "#dde3f6"
    readonly property color accent:  theme.accent || "#a98bff"
    readonly property color cyan:    theme.cyan || "#7fd6e6"
    readonly property color rose:    theme.rose || "#f28fb0"
    readonly property color danger:  theme.danger || "#ff7a95"
    readonly property string font:   "JetBrains Mono"

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // ── Backdrop: three slow bioluminescent glows ───────────────────────
    Rectangle { anchors.fill: parent; color: root.crust }
    Repeater {
        model: [
            { c: root.accent, s: 1.1, x: 0.22, y: 0.30, d: 23000 },
            { c: root.cyan,   s: 0.9, x: 0.80, y: 0.66, d: 29000 },
            { c: root.rose,   s: 0.6, x: 0.58, y: 0.16, d: 31000 }
        ]
        delegate: Shape {
            id: glow
            required property var modelData
            readonly property real size: Math.max(root.width, root.height) * modelData.s
            width: size
            height: size
            x: root.width * modelData.x - size / 2
            y: root.height * modelData.y - size / 2
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: -1
                strokeColor: "transparent"
                fillGradient: RadialGradient {
                    centerX: glow.size / 2; centerY: glow.size / 2; centerRadius: glow.size / 2
                    focalX: glow.size / 2; focalY: glow.size / 2
                    GradientStop { position: 0.0; color: Qt.rgba(glow.modelData.c.r, glow.modelData.c.g, glow.modelData.c.b, 0.16) }
                    GradientStop { position: 1.0; color: Qt.rgba(glow.modelData.c.r, glow.modelData.c.g, glow.modelData.c.b, 0) }
                }
                startX: 0; startY: 0
                PathLine { x: glow.size; y: 0 }
                PathLine { x: glow.size; y: glow.size }
                PathLine { x: 0; y: glow.size }
                PathLine { x: 0; y: 0 }
            }

            SequentialAnimation on y {
                loops: Animation.Infinite
                NumberAnimation { to: root.height * glow.modelData.y - glow.size / 2 - 40; duration: glow.modelData.d; easing.type: Easing.InOutSine }
                NumberAnimation { to: root.height * glow.modelData.y - glow.size / 2 + 40; duration: glow.modelData.d; easing.type: Easing.InOutSine }
            }
        }
    }

    // ── Time, date, password ────────────────────────────────────────────
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 10

        Text {
            text: Qt.formatDateTime(clock.date, "hh:mm")
            color: root.text
            font { family: root.font; pixelSize: 112; bold: true }
            Layout.alignment: Qt.AlignHCenter
        }
        Text {
            text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
            color: root.subtext
            font { family: root.font; pixelSize: 18 }
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 36
        }

        Rectangle {
            id: field
            implicitWidth: 340
            implicitHeight: 52
            radius: height / 2
            color: Qt.rgba(0.047, 0.063, 0.125, 0.85)
            border.width: 1.5
            border.color: root.lockRoot.error !== "" ? root.danger
                        : input.activeFocus ? Qt.rgba(0.66, 0.55, 1, 0.8) : Qt.rgba(0.87, 0.89, 0.96, 0.12)
            Layout.alignment: Qt.AlignHCenter
            Behavior on border.color { ColorAnimation { duration: 160 } }

            // Shake on a wrong password.
            transform: Translate { id: nudge }
            SequentialAnimation {
                id: shake
                NumberAnimation { target: nudge; property: "x"; to: 12; duration: 50 }
                NumberAnimation { target: nudge; property: "x"; to: -12; duration: 50 }
                NumberAnimation { target: nudge; property: "x"; to: 6; duration: 50 }
                NumberAnimation { target: nudge; property: "x"; to: 0; duration: 50 }
            }

            Text {
                anchors.centerIn: parent
                visible: input.text === ""
                text: root.lockRoot.busy ? "Checking…" : "Password"
                color: root.overlay
                font { family: root.font; pixelSize: 14 }
            }

            TextInput {
                id: input
                anchors { fill: parent; leftMargin: 24; rightMargin: 24 }
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignHCenter
                echoMode: TextInput.Password
                passwordCharacter: "•"
                color: root.text
                font { family: root.font; pixelSize: 18; letterSpacing: 4 }
                focus: true
                enabled: !root.lockRoot.busy
                clip: true

                onAccepted: {
                    root.lockRoot.submit(text)
                    text = ""
                }
                onTextChanged: if (text !== "") root.lockRoot.error = ""
                Keys.onEscapePressed: text = ""
            }
        }

        Text {
            text: root.lockRoot.error !== "" ? root.lockRoot.error : "Enter to unlock"
            color: root.lockRoot.error !== "" ? root.danger : root.overlay
            font { family: root.font; pixelSize: 12 }
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 4
        }
    }

    Connections {
        target: root.lockRoot
        function onErrorChanged() { if (root.lockRoot.error !== "") shake.start() }
    }

    Component.onCompleted: input.forceActiveFocus()
}
