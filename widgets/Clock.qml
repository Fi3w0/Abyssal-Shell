import QtQuick
import QtQuick.Layouts
import Quickshell
import "../components"
import "../services"

// Moon + time. Vertical bars stack moon / hours / minutes.
Item {
    id: root

    property var ctx
    readonly property bool vertical: ctx ? ctx.vertical : false

    SystemClock { id: clock; precision: SystemClock.Minutes }

    implicitWidth: vertical ? 32 : row.implicitWidth + 12
    implicitHeight: vertical ? col.implicitHeight + 8 : 28

    RowLayout {
        id: row
        visible: !root.vertical
        anchors.centerIn: parent
        spacing: 8
        Icon { name: "moon"; size: 14; stroke: 2.2; color: Theme.accent; Layout.alignment: Qt.AlignVCenter }
        Text {
            text: Qt.formatDateTime(clock.date, "hh:mm")
            color: Theme.text
            font { family: Theme.font; pixelSize: 13; bold: true }
            Layout.alignment: Qt.AlignVCenter
        }
    }

    ColumnLayout {
        id: col
        visible: root.vertical
        anchors.centerIn: parent
        spacing: 1
        Icon { name: "moon"; size: 13; stroke: 2.2; color: Theme.accent; Layout.alignment: Qt.AlignHCenter }
        Text {
            text: Qt.formatDateTime(clock.date, "hh")
            color: Theme.text
            font { family: Theme.font; pixelSize: 13; bold: true }
            Layout.alignment: Qt.AlignHCenter
        }
        Text {
            text: Qt.formatDateTime(clock.date, "mm")
            color: Theme.subtext
            font { family: Theme.font; pixelSize: 13; bold: true }
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
