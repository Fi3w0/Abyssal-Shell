import QtQuick
import QtQuick.Layouts
import Quickshell
import "../components"
import "../services"

// Moon + time, or time over date (option `date`, taskbar style).
// Vertical panels stack moon / hours / minutes.
Item {
    id: root

    property var ctx
    readonly property bool vertical: ctx ? ctx.vertical : false
    readonly property bool withDate: ctx && ctx.options ? ctx.options.date === true : false

    SystemClock { id: clock; precision: SystemClock.Minutes }

    implicitWidth: vertical ? 32 : (withDate ? dated.implicitWidth + 12 : row.implicitWidth + 12)
    implicitHeight: vertical ? col.implicitHeight + 8 : (withDate ? dated.implicitHeight + 4 : 28)

    RowLayout {
        id: row
        visible: !root.vertical && !root.withDate
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
        id: dated
        visible: !root.vertical && root.withDate
        anchors.centerIn: parent
        spacing: 0
        Text {
            text: Qt.formatDateTime(clock.date, "hh:mm")
            color: Theme.text
            font { family: Theme.font; pixelSize: 12; bold: true }
            Layout.alignment: Qt.AlignRight
        }
        Text {
            text: Qt.formatDateTime(clock.date, "dd/MM/yyyy")
            color: Theme.subtext
            font { family: Theme.font; pixelSize: 9 }
            Layout.alignment: Qt.AlignRight
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
