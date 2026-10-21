import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import "../components"
import "../services"

// Wi-Fi through the system NetworkManager, the same daemon Plasma talks
// to, so saved networks and passwords are shared with it. Scans while
// shown. A saved or open network connects on click; a new secured one asks
// for its password inline. Right click a saved network to forget it.
ColumnLayout {
    id: root

    property bool showBack: false
    // Scanning runs only while the page is on screen.
    property bool active: false
    signal back()

    spacing: 2

    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wired: Networking.devices.values.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var networks: {
        if (!wifi) return []
        return wifi.networks.values.filter(n => n.name !== "").sort((a, b) =>
            (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength))
    }
    readonly property var current: networks.find(n => n.connected) ?? null
    readonly property var others: networks.filter(n => !n.connected)

    // The network showing its password field or its actions.
    property var expanded: null
    // Name of the network whose last connection attempt failed.
    property string failed: ""

    onActiveChanged: if (!active) expanded = null

    Binding {
        target: root.wifi
        property: "scannerEnabled"
        value: root.active && Networking.wifiEnabled
        when: root.wifi !== null
    }

    function activate(net, mouse) {
        const secured = net.security !== WifiSecurityType.Open
        if (net.connected || (mouse && mouse.button === Qt.RightButton && net.known)) {
            expanded = expanded === net ? null : net
        } else if (net.known || !secured) {
            failed = ""
            expanded = null
            net.connect()
        } else {
            expanded = expanded === net ? null : net
        }
    }

    PageHeader {
        icon: "wifi"
        title: "Wi-Fi"
        showBack: root.showBack
        hasSwitch: true
        checked: Networking.wifiEnabled
        onBack: root.back()
        onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
    }

    Text {
        visible: !Networking.wifiEnabled || root.wifi === null
        text: !Networking.wifiEnabled ? "Wi-Fi is off." : "No Wi-Fi adapter found."
        color: Theme.subtext
        font { family: Theme.font; pixelSize: 11 }
        Layout.leftMargin: 4
        Layout.topMargin: 4
        Layout.bottomMargin: 6
    }

    ListRow {
        visible: root.wired !== null
        icon: "ethernet"
        title: "Ethernet"
        detail: root.wired ? "Connected · " + root.wired.name : ""
        active: true
    }

    SectionLabel {
        visible: root.current !== null && Networking.wifiEnabled
        text: "Connected"
    }
    NetworkRow {
        visible: root.current !== null && Networking.wifiEnabled
        page: root
        net: root.current
    }

    SectionLabel {
        visible: Networking.wifiEnabled && root.wifi !== null
        text: "Available"
        busy: root.active
    }
    Flickable {
        visible: Networking.wifiEnabled && root.wifi !== null
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 300)
        contentHeight: list.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: list
            width: parent.width
            Repeater {
                model: root.others
                NetworkRow {
                    required property var modelData
                    width: list.width
                    page: root
                    net: modelData
                }
            }
            Text {
                visible: root.others.length === 0
                text: root.active ? "Looking for networks…" : "No other networks"
                color: Theme.overlay
                font { family: Theme.font; pixelSize: 11 }
                leftPadding: 10
                topPadding: 6
                bottomPadding: 6
            }
        }
    }

    component NetworkRow: ColumnLayout {
        id: row

        property var page: null
        property var net: null
        readonly property bool open: page !== null && net !== null && page.expanded === net
        readonly property bool secured: net !== null && net.security !== WifiSecurityType.Open

        spacing: 0
        Layout.fillWidth: true

        function join() {
            if (!pw.text) return
            page.failed = ""
            net.connectWithPsk(pw.text)
            pw.text = ""
            page.expanded = null
        }

        Connections {
            target: row.net
            function onConnectionFailed(reason) {
                row.page.failed = row.net.name
                // Wrong or missing password: ask again.
                if (reason === ConnectionFailReason.NoSecrets || reason === ConnectionFailReason.WifiAuthTimeout)
                    row.page.expanded = row.net
            }
            function onConnectedChanged() { if (row.net.connected && row.page.failed === row.net.name) row.page.failed = "" }
        }

        ListRow {
            icon: "wifi"
            title: row.net ? row.net.name : ""
            active: row.net !== null && row.net.connected
            detail: !row.net ? ""
                : row.net.stateChanging ? (row.net.connected ? "Disconnecting…" : "Connecting…")
                : row.net.connected ? "Connected"
                : row.page && row.page.failed === row.net.name ? "Couldn't connect"
                : row.net.known ? "Saved" : row.secured ? "Secured" : "Open"
            onClicked: mouse => row.page.activate(row.net, mouse)

            Icon {
                visible: row.secured
                anchors.verticalCenter: parent.verticalCenter
                name: "lock"
                size: 12
                color: Theme.overlay
            }
            SignalBars {
                anchors.verticalCenter: parent.verticalCenter
                strength: row.net ? row.net.signalStrength : 0
                lit: row.net !== null && row.net.connected
            }
        }

        // New secured network: password field.
        RowLayout {
            visible: row.open && !row.net.known && !row.net.connected
            spacing: 6
            Layout.fillWidth: true
            Layout.leftMargin: 36
            Layout.rightMargin: 6
            Layout.bottomMargin: 8

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 30
                radius: 8
                color: Theme.alpha(Theme.crust, 0.6)
                border { width: 1; color: pw.activeFocus ? Theme.alpha(Theme.accent, 0.6) : Theme.hairline }

                TextInput {
                    id: pw
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    color: Theme.text
                    clip: true
                    selectByMouse: true
                    font { family: Theme.font; pixelSize: 12 }
                    onAccepted: row.join()
                    Keys.onEscapePressed: row.page.expanded = null
                }
                Text {
                    visible: pw.text === ""
                    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                    text: "Password"
                    color: Theme.overlay
                    font { family: Theme.font; pixelSize: 12 }
                }
            }
            TextButton {
                text: "Join"
                accent: true
                onClicked: row.join()
            }
        }
        onOpenChanged: if (open && !net.known) pw.forceActiveFocus()

        // Connected or saved network: actions.
        RowLayout {
            visible: row.open && (row.net.connected || row.net.known)
            spacing: 6
            Layout.leftMargin: 36
            Layout.bottomMargin: 8

            TextButton {
                visible: row.net !== null && row.net.connected
                text: "Disconnect"
                onClicked: { row.net.disconnect(); row.page.expanded = null }
            }
            TextButton {
                text: "Forget"
                danger: true
                onClicked: { row.net.forget(); row.page.expanded = null }
            }
        }
    }

    component SignalBars: Row {
        id: bars
        property real strength: 0
        property bool lit: false
        readonly property int level: Math.max(1, Math.ceil(strength * 4))
        spacing: 2
        Repeater {
            model: 4
            Rectangle {
                required property int index
                anchors.bottom: parent.bottom
                width: 2
                height: 3 + index * 2.6
                radius: 1
                color: index < bars.level ? (bars.lit ? Theme.cyan : Theme.subtext) : Theme.alpha(Theme.text, 0.15)
            }
        }
    }
}
