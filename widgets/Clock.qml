import QtQuick
import QtQuick.Layouts
import Quickshell
import "../components"
import "../services"

// Moon + time, or time over date (option `date`, taskbar style).
// Vertical panels stack moon / hours / minutes. Click opens the calendar
// with the notification centre beside it, or only the calendar (option
// `opens`).
Item {
    id: root

    property var ctx
    readonly property var opts: ctx && ctx.options ? ctx.options : ({})
    readonly property bool vertical: ctx ? ctx.vertical : false
    readonly property bool withDate: ctx && ctx.options ? ctx.options.date === true : false

    readonly property string timeFormat: (opts.hour24 === false ? "h:mm" : "hh:mm") + (opts.seconds === true ? ":ss" : "") + (opts.hour24 === false ? " AP" : "")
    SystemClock { id: clock; precision: root.opts.seconds === true ? SystemClock.Seconds : SystemClock.Minutes }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const p = mapToItem(null, width / 2, height / 2)
            Shell.toggleDetail(root.ctx.output, root.ctx.edge, root.opts.opens === "calendar" ? "calendar" : "clock",
                               root.vertical ? p.y : p.x, root.ctx.thickness)
        }
    }

    implicitWidth: vertical ? 32 : (withDate ? dated.implicitWidth + 12 : row.implicitWidth + 12)
    implicitHeight: vertical ? col.implicitHeight + 8 : (withDate ? dated.implicitHeight + 4 : 28)
    readonly property real minimumContentWidth: (vertical ? col.implicitWidth : withDate ? dated.implicitWidth : row.implicitWidth) + 2
    readonly property real minimumContentHeight: (vertical ? col.implicitHeight : withDate ? dated.implicitHeight : row.implicitHeight) + 2

    RowLayout {
        id: row
        visible: !root.vertical && !root.withDate
        anchors.centerIn: parent
        spacing: 8
        Icon { visible: root.opts.showIcon !== false; name: "moon"; size: 14; stroke: 2.2; color: Theme.accent; Layout.alignment: Qt.AlignVCenter }
        Text {
            text: Qt.formatDateTime(clock.date, root.timeFormat)
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
            text: Qt.formatDateTime(clock.date, root.timeFormat)
            color: Theme.text
            font { family: Theme.font; pixelSize: 12; bold: true }
            Layout.alignment: Qt.AlignRight
        }
        Text {
            text: Qt.formatDateTime(clock.date, root.opts.dateFormat || "dd/MM/yyyy")
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
        Icon { visible: root.opts.showIcon !== false; name: "moon"; size: 13; stroke: 2.2; color: Theme.accent; Layout.alignment: Qt.AlignHCenter }
        Text {
            text: root.opts.hour24 === false ? String(clock.date.getHours() % 12 || 12).padStart(2, "0") : Qt.formatDateTime(clock.date, "hh")
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
        Text {
            visible: root.opts.seconds === true
            text: Qt.formatDateTime(clock.date, "ss")
            color: Theme.subtext
            font { family: Theme.font; pixelSize: 10 }
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
