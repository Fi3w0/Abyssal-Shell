import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import "../components"
import "../services"

// Bluetooth through BlueZ. Paired devices connect or disconnect on click
// and show their battery; nearby devices pair on click (then get trusted
// and connected). Scans while shown. The trash button forgets a device.
ColumnLayout {
    id: root

    property bool showBack: false
    property bool active: false
    signal back()

    spacing: 2

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool on: adapter !== null && adapter.enabled
    readonly property var devices: adapter ? adapter.devices.values : []
    readonly property var mine: devices.filter(d => d.paired || d.bonded)
        .sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))
    // Unnamed devices only show their address; leave those out.
    readonly property var nearby: devices.filter(d => !d.paired && !d.bonded && d.deviceName !== "")
        .sort((a, b) => a.name.localeCompare(b.name))

    Binding {
        target: root.adapter
        property: "discovering"
        value: root.active && root.on
        when: root.adapter !== null
    }

    function iconFor(d) {
        const i = d.icon || ""
        if (i.startsWith("audio-head")) return "headphones"
        if (i.startsWith("audio")) return "speaker"
        if (i === "input-keyboard") return "keyboard"
        if (i === "input-mouse" || i === "input-tablet") return "mouse"
        if (i.startsWith("phone")) return "phone"
        return "bluetooth"
    }
    function stateText(d) {
        if (d.pairing) return "Pairing…"
        switch (d.state) {
        case BluetoothDeviceState.Connecting: return "Connecting…"
        case BluetoothDeviceState.Disconnecting: return "Disconnecting…"
        case BluetoothDeviceState.Connected: return "Connected"
        }
        return d.paired || d.bonded ? "Not connected" : "Click to pair"
    }

    PageHeader {
        icon: "bluetooth"
        title: "Bluetooth"
        showBack: root.showBack
        hasSwitch: root.adapter !== null
        checked: root.on
        onBack: root.back()
        onToggled: root.adapter.enabled = !root.adapter.enabled
    }

    Text {
        visible: !root.on
        text: root.adapter === null ? "No Bluetooth adapter found." : "Bluetooth is off."
        color: Theme.subtext
        font { family: Theme.font; pixelSize: 11 }
        Layout.leftMargin: 4
        Layout.topMargin: 4
        Layout.bottomMargin: 6
    }

    SectionLabel {
        visible: root.on && root.mine.length > 0
        text: "My devices"
    }
    Repeater {
        model: root.on ? root.mine : []
        DeviceRow { required property var modelData; page: root; device: modelData }
    }

    SectionLabel {
        visible: root.on
        text: "Nearby"
        busy: root.active
    }
    Flickable {
        visible: root.on
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 220)
        contentHeight: nearbyList.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: nearbyList
            width: parent.width
            Repeater {
                model: root.nearby
                DeviceRow { required property var modelData; width: nearbyList.width; page: root; device: modelData }
            }
            Text {
                visible: root.nearby.length === 0
                text: root.active ? "Looking for devices…" : "Nothing nearby"
                color: Theme.overlay
                font { family: Theme.font; pixelSize: 11 }
                leftPadding: 10
                topPadding: 6
                bottomPadding: 6
            }
        }
    }

    component DeviceRow: ListRow {
        id: row
        property var page: null
        property var device: null
        readonly property bool known: device !== null && (device.paired || device.bonded)

        icon: device && page ? page.iconFor(device) : "bluetooth"
        title: device ? device.name : ""
        detail: device && page ? page.stateText(device) : ""
        active: device !== null && device.connected
        onClicked: {
            if (!device || device.pairing) return
            if (!known) device.pair()
            else if (device.connected) device.disconnect()
            else device.connect()
        }

        // A device paired from here gets trusted (reconnects on its own)
        // and connected.
        Connections {
            target: row.device
            function onPairedChanged() {
                if (row.device.paired) { row.device.trusted = true; row.device.connect() }
            }
        }

        Text {
            visible: row.device !== null && row.device.batteryAvailable
            anchors.verticalCenter: parent.verticalCenter
            text: row.device ? Math.round(row.device.battery * 100) + "%" : ""
            color: row.device && row.device.battery < 0.2 ? Theme.warn : Theme.subtext
            font { family: Theme.font; pixelSize: 10 }
        }
        BarButton {
            visible: row.known && row.hovered
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: 24
            implicitHeight: 24
            icon: "trash"
            iconSize: 12
            iconColor: Theme.overlay
            onClicked: row.device.forget()
        }
    }
}
